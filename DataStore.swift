import Foundation

final class DataStore: ObservableObject {
    @Published var players: [Player] = []
    @Published var teams: [Team] = []
    @Published var competitions: [Competition] = []
    @Published var season: Season
    @Published var currentCareer: Career?

    private let saveKey = "fm_lite_save_v1"

    init() {
        let (p, t) = FakeData.makePlayersAndTeams()
        players = p
        teams = t
        competitions = FakeData.defaultCompetitions(teams: t)
        season = FakeData.defaultSeason(teams: t)
        loadCareer()
    }

    func createCareer(role: Role, teamID: UUID) {
        currentCareer = Career(role: role, teamID: teamID, createdAt: .now)
        saveCareer()
    }

    func saveCareer() {
        guard let career = currentCareer else { return }
        if let data = try? JSONEncoder().encode(career) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    func loadCareer() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        currentCareer = try? JSONDecoder().decode(Career.self, from: data)
    }

    func teamName(_ id: UUID) -> String { teams.first { $0.id == id }?.name ?? "Équipe" }

    func exportJSON() -> String {
        JSONImportExport.exportDatabaseToJSON(container: .init(players: players, teams: teams, competitions: competitions, season: season))
    }

    func importJSON(_ text: String) {
        guard let db = JSONImportExport.importDatabaseFromJSON(text) else { return }
        players = db.players; teams = db.teams; competitions = db.competitions; season = db.season
    }
}
