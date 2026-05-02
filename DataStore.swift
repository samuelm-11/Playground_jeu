import Foundation

final class DataStore: ObservableObject {
    @Published var players: [Player] = []
    @Published var teams: [Team] = []
    @Published var competitions: [Competition] = []
    @Published var season: Season
    @Published var currentCareer: Career?
    @Published var transferHistory: [TransferHistoryEntry] = []

    private let saveKey = "fm_lite_save_v3"

    init() {
        let (p, t) = FakeData.makePlayersAndTeams()
        players = p; teams = t; competitions = FakeData.defaultCompetitions(teams: t); season = FakeData.defaultSeason(teams: t)
        loadSaveOrBootstrap(); normalizeSquadsAndBudgets()
    }
    func normalizeSquadsAndBudgets() { for i in teams.indices { teams[i].wageBill = teamPlayers(teams[i].id).map(\.salary).reduce(0,+); teams[i].wageBudgetAvailable = max(0, teams[i].budget.wage - teams[i].wageBill) } }
    func createCareer(role: Role, teamID: UUID) { currentCareer = Career(role: role, teamID: teamID, createdAt: .now, selectedLineup: Array(teamPlayers(teamID).prefix(11).map(\.id)), tactic: .balanced, formation: "4-3-3"); saveAll() }
    func loadSaveOrBootstrap() { guard let data = UserDefaults.standard.data(forKey: saveKey), let db = try? JSONDecoder().decode(DatabaseContainer.self, from: data) else { return }; players = db.players; teams = db.teams; competitions = db.competitions; season = db.season; currentCareer = db.career; transferHistory = db.transferHistory }
    func saveAll() { let db = DatabaseContainer(players: players, teams: teams, competitions: competitions, season: season, career: currentCareer, transferHistory: transferHistory); if let data = try? JSONEncoder().encode(db) { UserDefaults.standard.set(data, forKey: saveKey) } }
    func teamName(_ id: UUID) -> String { teams.first { $0.id == id }?.name ?? "Équipe" }
    func teamPlayers(_ teamID: UUID) -> [Player] { players.filter { teams.first(where: { $0.id == teamID })?.playerIDs.contains($0.id) == true } }
    func nextMatchForCareer() -> MatchFixture? { guard let teamID = currentCareer?.teamID else { return nil }; return season.fixtures.first { !$0.played && ($0.homeTeamID == teamID || $0.awayTeamID == teamID) } }
    func fixturesForMatchday(_ matchday: Int) -> [MatchFixture] { season.fixtures.filter { $0.matchday == matchday }.sorted { $0.date < $1.date } }
    func canSimulateNextMatch() -> Bool { (currentCareer?.selectedLineup.count ?? 0) >= 11 }
    func setLineup(_ ids: [UUID]) { currentCareer?.selectedLineup = Array(ids.prefix(11)); saveAll() }
    func setTactic(_ tactic: Tactic) { currentCareer?.tactic = tactic; saveAll() }
    func setFormation(_ formation: String) { currentCareer?.formation = formation; saveAll() }

    func simulateNextMatchdayForCareer() -> UUID? { guard let teamID = currentCareer?.teamID, let next = nextMatchForCareer(), canSimulateNextMatch() else { return nil }; let day = next.matchday; guard currentCareer?.lastSimulatedMatchday != day else { return nil }; for f in fixturesForMatchday(day) where !f.played { simulateFixture(f.id, detailedComments: f.id == next.id) }; currentCareer?.lastSimulatedMatchday = day; recomputeTable(); updateRecoveryForNonStarters(teamID: teamID); updateNews(for: next.id); if day % 4 == 0 { simulateAITransfers() }; saveAll(); return next.id }

    private func simulateFixture(_ fixtureID: UUID, detailedComments: Bool) { guard let idx = season.fixtures.firstIndex(where: { $0.id == fixtureID }), !season.fixtures[idx].played else { return }; let f = season.fixtures[idx]; let home = teams.first { $0.id == f.homeTeamID }!; let away = teams.first { $0.id == f.awayTeamID }!; let hg = max(0, Int((1.2 + Double.random(in: -0.8...1.4)).rounded())); let ag = max(0, Int((1.0 + Double.random(in: -0.8...1.4)).rounded())); season.fixtures[idx].homeGoals = hg; season.fixtures[idx].awayGoals = ag; season.fixtures[idx].played = true; season.fixtures[idx].comments = detailedComments ? ["Coup d'envoi", "90' Fin du match"] : ["Match simulé automatiquement"]; updatePlayerStats(homeTeamID: home.id, awayTeamID: away.id, homeGoals: hg, awayGoals: ag); applyPostMatchImpacts(fixture: season.fixtures[idx]) }

    private func updatePlayerStats(homeTeamID: UUID, awayTeamID: UUID, homeGoals: Int, awayGoals: Int) {
        let homeSquad = teamPlayers(homeTeamID); let awaySquad = teamPlayers(awayTeamID)
        applyStatsForTeam(squad: homeSquad, goals: homeGoals, isManaged: homeTeamID == currentCareer?.teamID)
        applyStatsForTeam(squad: awaySquad, goals: awayGoals, isManaged: awayTeamID == currentCareer?.teamID)
    }
    private func applyStatsForTeam(squad: [Player], goals: Int, isManaged: Bool) {
        let starters = isManaged ? Set(currentCareer?.selectedLineup ?? Array(squad.prefix(11).map(\.id))) : Set(Array(squad.shuffled().prefix(11).map(\.id)) )
        for i in players.indices where squad.contains(where: { $0.id == players[i].id }) {
            if starters.contains(players[i].id) { players[i].stats.matchesPlayed += 1; players[i].stats.starts += 1; players[i].stats.minutesPlayed += Int.random(in: 65...95) }
            let perf = Double.random(in: 5.5...8.8); let mp = players[i].stats.matchesPlayed; players[i].stats.averageRating = ((players[i].stats.averageRating * Double(max(0, mp-1))) + perf) / Double(max(1, mp))
            if Int.random(in: 0...100) < 18 { players[i].stats.yellowCards += 1 }
            if Int.random(in: 0...100) < 3 { players[i].stats.redCards += 1 }
        }
        let attackers = squad.filter { [.st, .lw, .rw, .cm].contains($0.position) }
        for _ in 0..<goals { if let scorer = attackers.randomElement(), let idx = players.firstIndex(where: { $0.id == scorer.id }) { players[idx].stats.goals += 1; if Bool.random(), let assister = attackers.filter({$0.id != scorer.id}).randomElement(), let aidx = players.firstIndex(where: {$0.id == assister.id}) { players[aidx].stats.assists += 1 } } }
    }

    func toggleShortlist(playerID: UUID) { guard currentCareer != nil else { return }; if currentCareer!.shortlist.contains(playerID) { currentCareer!.shortlist.removeAll { $0 == playerID } } else { currentCareer!.shortlist.append(playerID) }; saveAll() }

    func makeOffer(playerID: UUID, amount: Double) -> String {
        guard let career = currentCareer, let pIndex = players.firstIndex(where: {$0.id==playerID}), let buyerIndex = teams.firstIndex(where: {$0.id==career.teamID}), let sellerIndex = teams.firstIndex(where: {$0.name==players[pIndex].club}) else { return "Erreur offre" }
        if teams[buyerIndex].budget.transfer < amount { return "Budget transfert insuffisant" }
        if teams[buyerIndex].wageBudgetAvailable < players[pIndex].salary { return "Budget salarial insuffisant" }
        let ratio = amount / players[pIndex].estimatedValue
        var chance = ratio < 0.8 ? 0.05 : (ratio <= 1.1 ? 0.45 : 0.82)
        if players[pIndex].potential > 82 || players[pIndex].overall > 80 || players[pIndex].age < 23 { chance -= 0.2 }
        let accepted = Double.random(in: 0...1) < max(0.02, chance)
        transferHistory.insert(.init(date: .now, playerID: playerID, fromTeamID: teams[sellerIndex].id, toTeamID: teams[buyerIndex].id, amount: amount, accepted: accepted), at: 0)
        if accepted { teams[buyerIndex].budget.transfer -= amount; teams[sellerIndex].playerIDs.removeAll{$0==playerID}; teams[buyerIndex].playerIDs.append(playerID); players[pIndex].club = teams[buyerIndex].name; currentCareer?.latestNews.insert("Transfert confirmé: \(players[pIndex].fullName)", at: 0); normalizeSquadsAndBudgets(); saveAll(); return "Offre acceptée" }
        currentCareer?.latestNews.insert("Offre refusée pour \(players[pIndex].fullName)", at: 0); saveAll(); return "Offre refusée"
    }
    private func simulateAITransfers() { guard let userID = currentCareer?.teamID else { return }; for _ in 0..<2 { guard let p = players.randomElement(), let seller = teams.first(where: {$0.name == p.club}), seller.id != userID, let buyer = teams.filter({$0.id != seller.id && $0.id != userID}).randomElement(), let pidx = players.firstIndex(where: {$0.id==p.id}), let sidx = teams.firstIndex(where: {$0.id==seller.id}), let bidx = teams.firstIndex(where: {$0.id==buyer.id}) else { continue }; let amount = p.estimatedValue * Double.random(in: 0.85...1.2); if amount < teams[bidx].budget.transfer && Bool.random() { teams[sidx].playerIDs.removeAll{$0==p.id}; teams[bidx].playerIDs.append(p.id); players[pidx].club = teams[bidx].name; transferHistory.insert(.init(date: .now, playerID: p.id, fromTeamID: seller.id, toTeamID: buyer.id, amount: amount, accepted: true), at: 0) } } }

    private func applyPostMatchImpacts(fixture: MatchFixture) { }
    private func updateRecoveryForNonStarters(teamID: UUID) { }
    private func updateNews(for fixtureID: UUID) { }
    func recomputeTable() { var map:[UUID:RankingEntry]=[:]; for t in teams { map[t.id]=RankingEntry(teamID:t.id)}; for f in season.fixtures where f.played { var h=map[f.homeTeamID]!,a=map[f.awayTeamID]!; h.played+=1;a.played+=1;h.goalsFor+=f.homeGoals;h.goalsAgainst+=f.awayGoals;a.goalsFor+=f.awayGoals;a.goalsAgainst+=f.homeGoals; if f.homeGoals>f.awayGoals {h.wins+=1;h.points+=3;a.losses+=1} else if f.homeGoals<f.awayGoals {a.wins+=1;a.points+=3;h.losses+=1} else {h.draws+=1;a.draws+=1;h.points+=1;a.points+=1}; map[f.homeTeamID]=h; map[f.awayTeamID]=a }; season.table=Array(map.values) }
    func exportJSON() -> String { JSONImportExport.exportDatabaseToJSON(container: .init(players: players, teams: teams, competitions: competitions, season: season, career: currentCareer, transferHistory: transferHistory)) }
    func importJSON(_ text: String) { guard let db = JSONImportExport.importDatabaseFromJSON(text) else { return }; players = db.players; teams = db.teams; competitions = db.competitions; season = db.season; currentCareer = db.career; transferHistory = db.transferHistory; saveAll() }
}
