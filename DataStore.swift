import Foundation

final class DataStore: ObservableObject {
    @Published var players: [Player] = []; @Published var teams: [Team] = []; @Published var competitions: [Competition] = []; @Published var season: Season
    @Published var currentCareer: Career?; @Published var transferHistory: [TransferHistoryEntry] = []
    private let saveKey = "fm_lite_save_v4"
    private let sources = ["La Gazette du Sport","L'Ameuse Sport","Le Vestiaire","Football Hebdo","The Matchday Times","El Diario del Fútbol","Calcio Notizie","Der Fussball Kurier"]

    init() { let (p,t)=FakeData.makePlayersAndTeams(); players=p; teams=t; competitions=FakeData.defaultCompetitions(teams:t); season=FakeData.defaultSeason(teams:t); loadSaveOrBootstrap(); normalizeSquadsAndBudgets() }
    func normalizeSquadsAndBudgets(){ for i in teams.indices { teams[i].wageBill=teamPlayers(teams[i].id).map(\.salary).reduce(0,+); teams[i].wageBudgetAvailable=max(0,teams[i].budget.wage-teams[i].wageBill) } }
    func createCareer(role: Role, teamID: UUID) { let goals=[BoardObjective(title:"Finir Top 5",progress:0),BoardObjective(title:"Atteindre demi-finale de coupe",progress:0),BoardObjective(title:"Masse salariale maîtrisée",progress:0.5)]; currentCareer = Career(role: role, teamID: teamID, createdAt: .now, selectedLineup: Array(teamPlayers(teamID).prefix(11).map(\.id)), board: BoardState(objectives: goals)); saveAll() }
    func loadSaveOrBootstrap(){ guard let data=UserDefaults.standard.data(forKey:saveKey), let db=try? JSONDecoder().decode(DatabaseContainer.self,from:data) else { return }; players=db.players; teams=db.teams; competitions=db.competitions; season=db.season; currentCareer=db.career; transferHistory=db.transferHistory }
    func saveAll(){ let db=DatabaseContainer(players:players,teams:teams,competitions:competitions,season:season,career:currentCareer,transferHistory:transferHistory); if let data=try? JSONEncoder().encode(db){ UserDefaults.standard.set(data, forKey: saveKey) } }
    func teamName(_ id: UUID)->String{ teams.first{$0.id==id}?.name ?? "Équipe" }
    func teamPlayers(_ teamID: UUID)->[Player]{ players.filter{ teams.first(where:{$0.id==teamID})?.playerIDs.contains($0.id)==true } }
    func nextMatchForCareer()->MatchFixture?{ guard let teamID=currentCareer?.teamID else{return nil}; return season.fixtures.first{ !$0.played && ($0.homeTeamID==teamID || $0.awayTeamID==teamID)} }
    func fixturesForMatchday(_ matchday:Int)->[MatchFixture]{ season.fixtures.filter{$0.matchday==matchday}.sorted{$0.date<$1.date} }
    func canSimulateNextMatch()->Bool{ (currentCareer?.selectedLineup.count ?? 0) >= 11 }
    func setLineup(_ ids:[UUID]){ currentCareer?.selectedLineup=Array(ids.prefix(11)); saveAll() }
    func setTactic(_ tactic:Tactic){ currentCareer?.tactic=tactic; saveAll() }
    func setFormation(_ formation:String){ currentCareer?.formation=formation; saveAll() }

    func simulateNextMatchdayForCareer() -> UUID? {
        guard let teamID=currentCareer?.teamID, let next=nextMatchForCareer(), canSimulateNextMatch() else { return nil }
        let day=next.matchday; guard currentCareer?.lastSimulatedMatchday != day else { return nil }
        var report = MatchCenterReport(fixtureID: next.id)
        report.status = .live
        for f in fixturesForMatchday(day) where !f.played { let detailed = f.id == next.id; simulateFixture(f.id, detailedComments: detailed, report: detailed ? &report : nil) }
        report.status = .finished; report.minute = 90; currentCareer?.lastMatchReport = report
        currentCareer?.lastSimulatedMatchday = day; recomputeTable(); updateRecoveryForNonStarters(teamID: teamID); reduceSuspensions(); updateBoard(); pushNews(title:"Journée \(day) terminée", category:.match)
        saveAll(); return next.id
    }

    private func simulateFixture(_ fixtureID: UUID, detailedComments: Bool, report: inout MatchCenterReport?) {
        guard let idx=season.fixtures.firstIndex(where:{$0.id==fixtureID}), !season.fixtures[idx].played else { return }
        let f=season.fixtures[idx]
        let managedHome = f.homeTeamID == currentCareer?.teamID
        let boost = formationAttackBoost() + tacticAttackBoost()
        let hg = max(0, Int((1.2 + (managedHome ? boost:0) + Double.random(in:-0.8...1.4)).rounded()))
        let ag = max(0, Int((1.0 + (!managedHome ? boost:0) + Double.random(in:-0.8...1.4)).rounded()))
        season.fixtures[idx].homeGoals=hg; season.fixtures[idx].awayGoals=ag; season.fixtures[idx].played=true
        var comments=["Coup d'envoi"]
        if detailed { report?.minute = 1 }
        for m in stride(from: 12, through: 90, by: Int.random(in: 11...17)) {
            if detailed, Bool.random() { let txt = "\(m)’ ⚽ Action dangereuse"; comments.append(txt); report?.events.append(.init(minute:m,icon:"⚡️",text:txt)) }
            if m == 45 { comments.append("45’ Mi-temps"); report?.events.append(.init(minute:45,icon:"⏸️",text:"45’ Mi-temps")) }
        }
        let end="90’ Fin du match : \(teamName(f.homeTeamID)) \(hg) - \(ag) \(teamName(f.awayTeamID))"; comments.append(end); report?.events.append(.init(minute:90,icon:"🏁",text:end))
        season.fixtures[idx].comments = detailedComments ? comments : ["Match simulé automatiquement"]
        updatePlayerStats(homeTeamID:f.homeTeamID, awayTeamID:f.awayTeamID, homeGoals:hg, awayGoals:ag, detailed:detailed, report:&report)
    }

    private func updatePlayerStats(homeTeamID: UUID, awayTeamID: UUID, homeGoals:Int, awayGoals:Int, detailed: Bool, report: inout MatchCenterReport?) {
        applyStatsForTeam(squad: teamPlayers(homeTeamID), goals: homeGoals, isManaged: homeTeamID == currentCareer?.teamID, report: &report)
        applyStatsForTeam(squad: teamPlayers(awayTeamID), goals: awayGoals, isManaged: awayTeamID == currentCareer?.teamID, report: &report)
        if detailed { report?.homeStats = makeTeamStats(goals: homeGoals); report?.awayStats = makeTeamStats(goals: awayGoals) }
    }
    private func makeTeamStats(goals:Int)->MatchTeamStats { .init(possession:Int.random(in:43...57), shots:Int.random(in:8...18), shotsOnTarget:Int.random(in:2...9), fouls:Int.random(in:7...18), yellows:Int.random(in:0...4), reds:Int.random(in:0...1), corners:Int.random(in:1...9), xg: Double(goals)+Double.random(in:0.3...1.8)) }

    private func applyStatsForTeam(squad:[Player], goals:Int, isManaged:Bool, report: inout MatchCenterReport?) {
        let starters = isManaged ? Set(currentCareer?.selectedLineup ?? Array(squad.prefix(11).map(\.id))) : Set(Array(squad.shuffled().prefix(11).map(\.id)))
        for i in players.indices where squad.contains(where:{$0.id==players[i].id}) {
            if starters.contains(players[i].id) { players[i].stats.matchesPlayed += 1; players[i].stats.starts += 1; players[i].stats.minutesPlayed += Int.random(in:65...95); players[i].fitness=max(25, players[i].fitness-Int.random(in:4...12)) }
            let perf = Double.random(in:5.4...8.9); let mp=max(1,players[i].stats.matchesPlayed); players[i].stats.averageRating=((players[i].stats.averageRating*Double(mp-1))+perf)/Double(mp)
            if Int.random(in:0...100)<16 { players[i].stats.yellowCards += 1; players[i].yellowCardsAccumulated += 1; if players[i].yellowCardsAccumulated >= 5 { players[i].status = .suspended; players[i].suspensionMatchesRemaining = 1; players[i].yellowCardsAccumulated = 0 } }
            if Int.random(in:0...100)<2 { players[i].stats.redCards += 1; players[i].status = .suspended; players[i].suspensionMatchesRemaining = 1 }
            if Int.random(in:0...100)<4 { players[i].status = .injured; players[i].injuryDaysRemaining = Int.random(in:4...25); if isManaged { pushNews(title:"Blessure: \(players[i].fullName) absent \(players[i].injuryDaysRemaining) jours", category:.injury) } }
            if isManaged && starters.contains(players[i].id) { report?.ratings.append(.init(playerID: players[i].id, rating: perf)) }
        }
        let attackers=squad.filter{[.st,.lw,.rw,.cm].contains($0.position)}
        for _ in 0..<goals { if let scorer=attackers.randomElement(), let idx=players.firstIndex(where:{$0.id==scorer.id}) { players[idx].stats.goals += 1; if Bool.random(), let assister=attackers.filter({$0.id != scorer.id}).randomElement(), let aidx=players.firstIndex(where:{$0.id==assister.id}) { players[aidx].stats.assists += 1 } } }
        report?.playerOfTheMatchID = report?.ratings.max(by: {$0.rating < $1.rating})?.playerID
    }

    private func formationAttackBoost()->Double { switch currentCareer?.formation { case "4-3-3": return 0.25; case "4-2-3-1": return 0.15; case "3-5-2": return 0.1; case "5-3-2": return -0.2; default: return 0 } }
    private func tacticAttackBoost()->Double { switch currentCareer?.tactic { case .defensive: return -0.25; case .offensive: return 0.25; default: return 0 } }
    private func updateRecoveryForNonStarters(teamID: UUID){
        let ids = Set(currentCareer?.selectedLineup ?? [])
        for i in players.indices where players[i].club == teamName(teamID) {
            if !ids.contains(players[i].id) { players[i].fitness = min(100, players[i].fitness + 8) }
            players[i].injuryDaysRemaining = max(0, players[i].injuryDaysRemaining - 7)
            if players[i].injuryDaysRemaining == 0 && players[i].status == .injured { players[i].status = .available }
        }
    }
    private func reduceSuspensions(){ guard let teamID=currentCareer?.teamID else{return}; for i in players.indices where players[i].club == teamName(teamID) && players[i].suspensionMatchesRemaining>0 { players[i].suspensionMatchesRemaining -= 1; if players[i].suspensionMatchesRemaining<=0 && players[i].status == .suspended { players[i].status = .available } } }
    private func updateBoard(){ guard let teamID=currentCareer?.teamID else{return}; let rows = season.table.sorted{ $0.points == $1.points ? $0.goalDifference > $1.goalDifference : $0.points > $1.points }; let rank=(rows.firstIndex(where:{$0.teamID==teamID}) ?? rows.count-1)+1; var sat=max(20, 85-rank*6); if teamPlayers(teamID).filter({$0.fitness < 40}).count > 3 { sat -= 5 }; currentCareer?.board.satisfaction = sat; currentCareer?.board.riskLevel = sat < 35 ? "Élevé" : (sat < 55 ? "Moyen" : "Faible"); currentCareer?.board.comment = sat < 45 ? "Le board veut une réaction immédiate." : "Le board reste confiant."; if sat < 40 { pushNews(title:"Pression du board en hausse", category:.board) } }
    private func pushNews(title:String, category:NewsCategory){ currentCareer?.latestNews.insert(title, at: 0); currentCareer?.newsFeed.insert(.init(date:.now, source:sources.randomElement()!, title:title, category:category), at:0) }

    func toggleShortlist(playerID: UUID) { guard currentCareer != nil else { return }; if currentCareer!.shortlist.contains(playerID) { currentCareer!.shortlist.removeAll { $0 == playerID } } else { currentCareer!.shortlist.append(playerID) }; saveAll() }
    func makeOffer(playerID: UUID, amount: Double) -> String {
        guard let career = currentCareer, let pIndex = players.firstIndex(where: {$0.id==playerID}), let buyerIndex = teams.firstIndex(where: {$0.id==career.teamID}), let sellerIndex = teams.firstIndex(where: {$0.name==players[pIndex].club}) else { return "Erreur offre" }
        if teams[buyerIndex].budget.transfer < amount { return "Budget transfert insuffisant" }
        if teams[buyerIndex].wageBudgetAvailable < players[pIndex].salary { return "Budget salarial insuffisant" }
        let accepted = Double.random(in: 0...1) < 0.5
        transferHistory.insert(.init(date: .now, playerID: playerID, fromTeamID: teams[sellerIndex].id, toTeamID: teams[buyerIndex].id, amount: amount, accepted: accepted), at: 0)
        if accepted { teams[buyerIndex].budget.transfer -= amount; teams[sellerIndex].playerIDs.removeAll{$0==playerID}; teams[buyerIndex].playerIDs.append(playerID); players[pIndex].club = teams[buyerIndex].name; pushNews(title:"Transfert confirmé: \(players[pIndex].fullName)", category:.transfer); normalizeSquadsAndBudgets(); saveAll(); return "Offre acceptée" }
        pushNews(title:"Offre refusée pour \(players[pIndex].fullName)", category:.transfer); saveAll(); return "Offre refusée"
    }
    func recomputeTable() { var map:[UUID:RankingEntry]=[:]; for t in teams { map[t.id]=RankingEntry(teamID:t.id)}; for f in season.fixtures where f.played { var h=map[f.homeTeamID]!,a=map[f.awayTeamID]!; h.played+=1;a.played+=1;h.goalsFor+=f.homeGoals;h.goalsAgainst+=f.awayGoals;a.goalsFor+=f.awayGoals;a.goalsAgainst+=f.homeGoals; if f.homeGoals>f.awayGoals {h.wins+=1;h.points+=3;a.losses+=1} else if f.homeGoals<f.awayGoals {a.wins+=1;a.points+=3;h.losses+=1} else {h.draws+=1;a.draws+=1;h.points+=1;a.points+=1}; map[f.homeTeamID]=h; map[f.awayTeamID]=a }; season.table=Array(map.values) }
    func exportJSON() -> String { JSONImportExport.exportDatabaseToJSON(container: .init(players: players, teams: teams, competitions: competitions, season: season, career: currentCareer, transferHistory: transferHistory)) }
    func importJSON(_ text: String) { guard let db = JSONImportExport.importDatabaseFromJSON(text) else { return }; players = db.players; teams = db.teams; competitions = db.competitions; season = db.season; currentCareer = db.career; transferHistory = db.transferHistory; saveAll() }
}
