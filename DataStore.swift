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

    func canSimulateNextMatch() -> Bool {
        guard let c = currentCareer else { return false }
        return c.selectedLineup.count >= 11
    }

    func setLineup(_ ids: [UUID]) { currentCareer?.selectedLineup = Array(ids.prefix(11)); saveAll() }
    func setTactic(_ tactic: Tactic) { currentCareer?.tactic = tactic; saveAll() }

    func simulateMatch(_ fixtureID: UUID) {
        guard let idx = season.fixtures.firstIndex(where: { $0.id == fixtureID }), !season.fixtures[idx].played else { return }
        guard let career = currentCareer else { return }
        let f = season.fixtures[idx]
        let homeTeam = teams.first { $0.id == f.homeTeamID }!
        let awayTeam = teams.first { $0.id == f.awayTeamID }!

        let homeStats = computeStrength(teamID: homeTeam.id, applyingCareerBonusIfManaged: homeTeam.id == career.teamID)
        let awayStats = computeStrength(teamID: awayTeam.id, applyingCareerBonusIfManaged: awayTeam.id == career.teamID)
        let homeBase = 1.2 + (homeStats.rating - awayStats.rating) / 30 + 0.25
        let awayBase = 1.0 + (awayStats.rating - homeStats.rating) / 30

        let hg = max(0, Int((homeBase + Double.random(in: -0.8...1.0)).rounded()))
        let ag = max(0, Int((awayBase + Double.random(in: -0.8...1.0)).rounded()))
        var comments = ["Coup d'envoi"]
        for m in stride(from: 10, through: 90, by: 10) {
            let e = Int.random(in: 0...4)
            if e == 0 { comments.append("\(m)' Occasion pour \(Bool.random() ? homeTeam.name : awayTeam.name)") }
            if e == 1 { comments.append("\(m)' Carton jaune") }
            if e == 2 { comments.append("\(m)' Blessure légère") }
            if e == 3 { comments.append("\(m)' Changement de dynamique") }
        }
        comments.append("90' Fin du match")

        season.fixtures[idx].homeGoals = hg
        season.fixtures[idx].awayGoals = ag
        season.fixtures[idx].played = true
        season.fixtures[idx].comments = comments
        recomputeTable()
        saveAll()
    }

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
