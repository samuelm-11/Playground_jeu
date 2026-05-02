import Foundation

final class DataStore: ObservableObject {
    @Published var players: [Player] = []
    @Published var teams: [Team] = []
    @Published var competitions: [Competition] = []
    @Published var season: Season
    @Published var currentCareer: Career?

    private let saveKey = "fm_lite_save_v2"

    init() {
        let (p, t) = FakeData.makePlayersAndTeams()
        players = p; teams = t; competitions = FakeData.defaultCompetitions(teams: t); season = FakeData.defaultSeason(teams: t)
        loadSaveOrBootstrap()
    }

    func createCareer(role: Role, teamID: UUID) {
        currentCareer = Career(role: role, teamID: teamID, createdAt: .now, selectedLineup: Array(teamPlayers(teamID).prefix(11).map(\.id)), tactic: .balanced)
        saveAll()
    }

    func loadSaveOrBootstrap() {
        guard let data = UserDefaults.standard.data(forKey: saveKey), let db = try? JSONDecoder().decode(DatabaseContainer.self, from: data) else { return }
        players = db.players; teams = db.teams; competitions = db.competitions; season = db.season; currentCareer = db.career
    }

    func saveAll() {
        let db = DatabaseContainer(players: players, teams: teams, competitions: competitions, season: season, career: currentCareer)
        if let data = try? JSONEncoder().encode(db) { UserDefaults.standard.set(data, forKey: saveKey) }
    }

    func teamName(_ id: UUID) -> String { teams.first { $0.id == id }?.name ?? "Équipe" }
    func teamPlayers(_ teamID: UUID) -> [Player] { players.filter { teams.first(where: { $0.id == teamID })?.playerIDs.contains($0.id) == true } }

    func nextMatchForCareer() -> MatchFixture? {
        guard let teamID = currentCareer?.teamID else { return nil }
        return season.fixtures.first { !$0.played && ($0.homeTeamID == teamID || $0.awayTeamID == teamID) }
    }

    func fixturesForMatchday(_ matchday: Int) -> [MatchFixture] {
        season.fixtures.filter { $0.matchday == matchday }.sorted { $0.date < $1.date }
    }

    func canSimulateNextMatch() -> Bool {
        guard let c = currentCareer else { return false }
        return c.selectedLineup.count >= 11
    }

    func setLineup(_ ids: [UUID]) { currentCareer?.selectedLineup = Array(ids.prefix(11)); saveAll() }
    func setTactic(_ tactic: Tactic) { currentCareer?.tactic = tactic; saveAll() }

    func simulateNextMatchdayForCareer() -> UUID? {
        guard let teamID = currentCareer?.teamID, let next = nextMatchForCareer(), canSimulateNextMatch() else { return nil }
        let matchday = next.matchday
        guard currentCareer?.lastSimulatedMatchday != matchday else { return nil }

        let dayFixtures = fixturesForMatchday(matchday)
        guard dayFixtures.contains(where: { $0.homeTeamID == teamID || $0.awayTeamID == teamID }) else { return nil }

        for f in dayFixtures where !f.played {
            simulateFixture(f.id, detailedComments: f.id == next.id)
        }

        currentCareer?.lastSimulatedMatchday = matchday
        recomputeTable()
        updateRecoveryForNonStarters(teamID: teamID)
        updateNews(for: next.id)
        saveAll()
        return next.id
    }

    private func simulateFixture(_ fixtureID: UUID, detailedComments: Bool) {
        guard let idx = season.fixtures.firstIndex(where: { $0.id == fixtureID }), !season.fixtures[idx].played else { return }
        let f = season.fixtures[idx]
        let homeTeam = teams.first { $0.id == f.homeTeamID }!
        let awayTeam = teams.first { $0.id == f.awayTeamID }!

        let homeStats = computeStrength(teamID: homeTeam.id, applyingCareerBonusIfManaged: homeTeam.id == currentCareer?.teamID)
        let awayStats = computeStrength(teamID: awayTeam.id, applyingCareerBonusIfManaged: awayTeam.id == currentCareer?.teamID)
        let homeBase = 1.2 + (homeStats.rating - awayStats.rating) / 30 + 0.25
        let awayBase = 1.0 + (awayStats.rating - homeStats.rating) / 30

        let hg = max(0, Int((homeBase + Double.random(in: -0.8...1.0)).rounded()))
        let ag = max(0, Int((awayBase + Double.random(in: -0.8...1.0)).rounded()))

        var comments: [String] = []
        if detailedComments {
            comments = ["Coup d'envoi"]
            for m in stride(from: 10, through: 90, by: 10) {
                switch Int.random(in: 0...4) {
                case 0: comments.append("\(m)' Occasion pour \(Bool.random() ? homeTeam.name : awayTeam.name)")
                case 1: comments.append("\(m)' Carton jaune")
                case 2: comments.append("\(m)' Blessure légère")
                case 3: comments.append("\(m)' Changement de dynamique")
                default: break
                }
            }
            comments.append("90' Fin du match")
        } else {
            comments = ["Match simulé automatiquement"]
        }

        season.fixtures[idx].homeGoals = hg
        season.fixtures[idx].awayGoals = ag
        season.fixtures[idx].played = true
        season.fixtures[idx].comments = comments

        applyPostMatchImpacts(fixture: season.fixtures[idx])
    }

    private func applyPostMatchImpacts(fixture: MatchFixture) {
        guard let teamID = currentCareer?.teamID else { return }
        guard fixture.homeTeamID == teamID || fixture.awayTeamID == teamID else { return }

        let resultDelta: Int
        if (fixture.homeTeamID == teamID && fixture.homeGoals > fixture.awayGoals) || (fixture.awayTeamID == teamID && fixture.awayGoals > fixture.homeGoals) {
            resultDelta = 5
        } else if fixture.homeGoals == fixture.awayGoals {
            resultDelta = 1
        } else {
            resultDelta = -4
        }

        let lineup = Set(currentCareer?.selectedLineup ?? [])
        for i in players.indices {
            guard players[i].club == teamName(teamID) else { continue }
            if lineup.contains(players[i].id) {
                players[i].morale = clamp(players[i].morale + resultDelta)
                players[i].fitness = clamp(players[i].fitness - 8)
            }
        }
    }

    private func updateRecoveryForNonStarters(teamID: UUID) {
        let lineup = Set(currentCareer?.selectedLineup ?? [])
        for i in players.indices {
            guard players[i].club == teamName(teamID), !lineup.contains(players[i].id) else { continue }
            players[i].fitness = clamp(players[i].fitness + 3)
        }
    }

    private func updateNews(for fixtureID: UUID) {
        guard let f = season.fixtures.first(where: { $0.id == fixtureID }), let teamID = currentCareer?.teamID else { return }
        let isHome = f.homeTeamID == teamID
        let gf = isHome ? f.homeGoals : f.awayGoals
        let ga = isHome ? f.awayGoals : f.homeGoals
        let lastResult = "Dernier match: \(teamName(f.homeTeamID)) \(f.homeGoals)-\(f.awayGoals) \(teamName(f.awayTeamID))"
        let best = teamPlayers(teamID).max(by: { $0.overall < $1.overall })?.fullName ?? "N/A"
        let morale = Int(teamPlayers(teamID).map(\.morale).reduce(0,+) / max(teamPlayers(teamID).count, 1))
        let evolution = gf > ga ? "Moral en hausse" : (gf == ga ? "Moral stable" : "Moral en baisse")
        let nextOpponent = nextMatchForCareer().map { teamName($0.homeTeamID == teamID ? $0.awayTeamID : $0.homeTeamID) } ?? "Saison terminée"
        currentCareer?.latestNews = [lastResult, "Meilleur joueur: \(best)", "\(evolution) (moyenne: \(morale))", "Prochain adversaire: \(nextOpponent)"]
    }

    private func clamp(_ value: Int) -> Int { min(100, max(0, value)) }

    private func computeStrength(teamID: UUID, applyingCareerBonusIfManaged: Bool) -> (rating: Double, morale: Double, fitness: Double) {
        let squad = teamPlayers(teamID)
        let lineup: [Player]
        if applyingCareerBonusIfManaged, let c = currentCareer, c.selectedLineup.count >= 11 {
            lineup = squad.filter { c.selectedLineup.contains($0.id) }
        } else { lineup = squad }
        let base = lineup.isEmpty ? squad : lineup
        let rating = Double(base.map(\.overall).reduce(0,+)) / Double(max(base.count, 1))
        let morale = Double(base.map(\.morale).reduce(0,+)) / Double(max(base.count, 1))
        let fitness = Double(base.map(\.fitness).reduce(0,+)) / Double(max(base.count, 1))
        var mod = 0.0
        if applyingCareerBonusIfManaged {
            switch currentCareer?.tactic ?? .balanced {
            case .defensive: mod -= 0.2
            case .balanced: mod += 0
            case .offensive: mod += 0.2
            }
        }
        return (rating + (morale-70)/25 + (fitness-70)/25 + mod, morale, fitness)
    }

    func recomputeTable() {
        var map: [UUID: RankingEntry] = [:]
        for t in teams { map[t.id] = RankingEntry(teamID: t.id) }
        for f in season.fixtures where f.played {
            var h = map[f.homeTeamID]!, a = map[f.awayTeamID]!
            h.played += 1; a.played += 1
            h.goalsFor += f.homeGoals; h.goalsAgainst += f.awayGoals
            a.goalsFor += f.awayGoals; a.goalsAgainst += f.homeGoals
            if f.homeGoals > f.awayGoals { h.wins += 1; h.points += 3; a.losses += 1 }
            else if f.homeGoals < f.awayGoals { a.wins += 1; a.points += 3; h.losses += 1 }
            else { h.draws += 1; a.draws += 1; h.points += 1; a.points += 1 }
            map[f.homeTeamID] = h; map[f.awayTeamID] = a
        }
        season.table = Array(map.values)
    }

    func exportJSON() -> String { JSONImportExport.exportDatabaseToJSON(container: .init(players: players, teams: teams, competitions: competitions, season: season, career: currentCareer)) }
    func importJSON(_ text: String) { guard let db = JSONImportExport.importDatabaseFromJSON(text) else { return }; players = db.players; teams = db.teams; competitions = db.competitions; season = db.season; currentCareer = db.career; saveAll() }
}
