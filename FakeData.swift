import Foundation

enum FakeData {
    static func makePlayersAndTeams() -> (players: [Player], teams: [Team]) {
        let teamNames = ["Paris Aurora", "Lyon Titans", "Marseille Wave", "Nice Falcons", "Lille Storm", "Monaco Kings", "Rennes Foxes", "Nantes Harbor"]
        let firstNames = ["Lucas", "Noah", "Liam", "Ethan", "Hugo", "Mason", "Leo", "Adam", "Nolan", "Gabriel"]
        let lastNames = ["Martin", "Bernard", "Petit", "Robert", "Richard", "Durand", "Dubois", "Moreau", "Laurent", "Simon"]
        let positions: [Position] = [.gk,.cb,.cb,.lb,.rb,.cm,.cm,.lw,.rw,.st,.st,.cm,.cb,.rw,.st]
        var players: [Player] = []; var teams: [Team] = []
        for (idx, teamName) in teamNames.enumerated() {
            var ids: [UUID] = []
            for i in 0..<15 {
                let p = Player(firstName: firstNames[(i + idx) % firstNames.count], lastName: lastNames[(i * 2 + idx) % lastNames.count], age: Int.random(in: 18...33), nationality: ["France","Espagne","Italie","Portugal"][i % 4], position: positions[i], club: teamName, overall: 62 + Int.random(in: 0...20), potential: 68 + Int.random(in: 0...20), salary: Double.random(in: 12000...70000), estimatedValue: Double.random(in: 1_000_000...25_000_000), morale: Int.random(in: 55...95), fitness: Int.random(in: 55...95))
                players.append(p); ids.append(p.id)
            }
            teams.append(Team(name: teamName, country: "France", league: "Ligue Playground", budget: .init(global: 80_000_000, transfer: 20_000_000, wage: 3_000_000), reputation: 60 + idx * 4, playerIDs: ids))
        }
        return (players, teams)
    }

    static func defaultCompetitions(teams: [Team]) -> [Competition] { [.init(name: "Ligue Playground", country: "France", type: .league, teamIDs: teams.map(\.id))] }

    static func defaultSeason(teams: [Team]) -> Season {
        var fixtures: [MatchFixture] = []
        let startDate = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 12)) ?? .now
        var day = 1
        for i in 0..<teams.count {
            for j in (i+1)..<teams.count {
                fixtures.append(.init(matchday: day, homeTeamID: teams[i].id, awayTeamID: teams[j].id, date: startDate.addingTimeInterval(Double(day - 1) * 86400 * 7)))
                day += 1
                fixtures.append(.init(matchday: day, homeTeamID: teams[j].id, awayTeamID: teams[i].id, date: startDate.addingTimeInterval(Double(day - 1) * 86400 * 7)))
                day += 1
            }
        }
        return Season(yearLabel: "2026/2027", fixtures: fixtures.sorted { $0.date < $1.date }, table: teams.map { RankingEntry(teamID: $0.id) })
    }
}
