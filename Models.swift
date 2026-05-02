import Foundation

enum Role: String, CaseIterable, Codable, Identifiable {
    case coach = "Entraîneur"
    case sportingDirector = "Directeur sportif"
    case president = "Président"
    var id: String { rawValue }
}

enum Position: String, CaseIterable, Codable, Identifiable {
    case gk = "GB", cb = "DC", lb = "DG", rb = "DD", cm = "MC", lw = "AG", rw = "AD", st = "BU"
    var id: String { rawValue }
}

enum CompetitionType: String, CaseIterable, Codable, Identifiable {
    case league = "Championnat", cup = "Coupe", european = "Européen"
    var id: String { rawValue }
}

struct Budget: Codable {
    var global: Double
    var transfer: Double
    var wage: Double
}

struct Staff: Identifiable, Codable {
    var id = UUID()
    var name: String
    var role: String
    var level: Int
}

struct Player: Identifiable, Codable {
    var id = UUID()
    var firstName: String
    var lastName: String
    var age: Int
    var nationality: String
    var position: Position
    var club: String
    var overall: Int
    var potential: Int
    var salary: Double
    var estimatedValue: Double
    var morale: Int
    var fitness: Int
    var fullName: String { "\(firstName) \(lastName)" }
}

struct Team: Identifiable, Codable {
    var id = UUID()
    var name: String
    var country: String
    var league: String
    var budget: Budget
    var reputation: Int
    var playerIDs: [UUID]

    func averageRating(players: [Player]) -> Double {
        let squad = players.filter { playerIDs.contains($0.id) }
        guard !squad.isEmpty else { return 60 }
        return Double(squad.map(\.overall).reduce(0, +)) / Double(squad.count)
    }
}

struct Competition: Identifiable, Codable {
    var id = UUID()
    var name: String
    var country: String
    var type: CompetitionType
    var teamIDs: [UUID]
}

struct Transfer: Identifiable, Codable {
    var id = UUID()
    var playerID: UUID
    var fromTeamID: UUID
    var toTeamID: UUID
    var amount: Double
}

struct MatchFixture: Identifiable, Codable {
    var id = UUID()
    var homeTeamID: UUID
    var awayTeamID: UUID
    var date: Date
    var played = false
    var homeGoals = 0
    var awayGoals = 0
}

struct RankingEntry: Identifiable, Codable {
    var id = UUID()
    var teamID: UUID
    var played = 0
    var wins = 0
    var draws = 0
    var losses = 0
    var goalsFor = 0
    var goalsAgainst = 0
    var points = 0
}

struct Season: Codable {
    var yearLabel: String
    var fixtures: [MatchFixture]
    var table: [RankingEntry]
}

struct Career: Codable {
    var role: Role
    var teamID: UUID
    var createdAt: Date
}

struct DatabaseContainer: Codable {
    var players: [Player]
    var teams: [Team]
    var competitions: [Competition]
    var season: Season
}
