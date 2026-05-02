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

enum Tactic: String, CaseIterable, Codable, Identifiable {
    case defensive = "Défensif", balanced = "Équilibré", offensive = "Offensif"
    var id: String { rawValue }
}

enum CompetitionType: String, CaseIterable, Codable, Identifiable {
    case league = "Championnat", cup = "Coupe", european = "Européen"
    var id: String { rawValue }
}

enum PlayerStatus: String, CaseIterable, Codable, Identifiable {
    case available = "Disponible", injured = "Blessé", suspended = "Suspendu"
    var id: String { rawValue }
}

struct Budget: Codable { var global: Double; var transfer: Double; var wage: Double }
struct Staff: Identifiable, Codable { var id = UUID(); var name: String; var role: String; var level: Int }

struct PlayerSeasonStats: Codable {
    var matchesPlayed = 0
    var starts = 0
    var goals = 0
    var assists = 0
    var yellowCards = 0
    var redCards = 0
    var averageRating = 0.0
    var minutesPlayed = 0
}

struct Player: Identifiable, Codable {
    var id = UUID(); var firstName: String; var lastName: String; var age: Int; var nationality: String
    var position: Position; var club: String; var overall: Int; var potential: Int; var salary: Double; var estimatedValue: Double; var morale: Int; var fitness: Int
    var status: PlayerStatus = .available
    var contractUntilYear: Int = 2028
    var stats: PlayerSeasonStats = .init()
    var fullName: String { "\(firstName) \(lastName)" }
}

struct Team: Identifiable, Codable {
    var id = UUID(); var name: String; var country: String; var league: String; var budget: Budget; var reputation: Int; var playerIDs: [UUID]
    var wageBill: Double = 0
    var wageBudgetAvailable: Double = 0
}

struct Competition: Identifiable, Codable { var id = UUID(); var name: String; var country: String; var type: CompetitionType; var teamIDs: [UUID] }
struct Transfer: Identifiable, Codable { var id = UUID(); var playerID: UUID; var fromTeamID: UUID; var toTeamID: UUID; var amount: Double }

struct TransferHistoryEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var playerID: UUID
    var fromTeamID: UUID
    var toTeamID: UUID
    var amount: Double
    var accepted: Bool
}

struct MatchFixture: Identifiable, Codable {
    var id = UUID()
    var matchday: Int
    var homeTeamID: UUID
    var awayTeamID: UUID
    var date: Date
    var played = false
    var homeGoals = 0
    var awayGoals = 0
    var comments: [String] = []
}

struct RankingEntry: Identifiable, Codable {
    var id = UUID(); var teamID: UUID
    var played = 0; var wins = 0; var draws = 0; var losses = 0; var goalsFor = 0; var goalsAgainst = 0; var points = 0
    var goalDifference: Int { goalsFor - goalsAgainst }
}

struct Season: Codable { var yearLabel: String; var fixtures: [MatchFixture]; var table: [RankingEntry] }

struct Career: Codable {
    var role: Role
    var teamID: UUID
    var createdAt: Date
    var selectedLineup: [UUID] = []
    var tactic: Tactic = .balanced
    var lastSimulatedMatchday: Int?
    var latestNews: [String] = []
    var shortlist: [UUID] = []
}

struct DatabaseContainer: Codable {
    var players: [Player]; var teams: [Team]; var competitions: [Competition]; var season: Season; var career: Career?
    var transferHistory: [TransferHistoryEntry] = []
}
