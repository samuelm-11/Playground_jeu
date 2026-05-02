import Foundation

enum FakeData {
    static func makePlayersAndTeams() -> (players: [Player], teams: [Team]) {
        let teamNames = ["Paris Aurora", "Lyon Titans", "Marseille Wave", "Nice Falcons", "Lille Storm", "Monaco Kings", "Rennes Foxes", "Nantes Harbor"]
        let firstNames = ["Lucas", "Noah", "Liam", "Ethan", "Hugo", "Mason", "Leo", "Adam", "Nolan", "Gabriel"]
        let lastNames = ["Martin", "Bernard", "Petit", "Robert", "Richard", "Durand", "Dubois", "Moreau", "Laurent", "Simon"]
        let positions: [Position] = [.gk,.gk,.cb,.cb,.cb,.lb,.rb,.cm,.cm,.cm,.lw,.rw,.st,.st,.st,.cm,.cb,.lb,.rb,.rw]
        var players: [Player] = []; var teams: [Team] = []
        for (idx, teamName) in teamNames.enumerated() {
            var ids: [UUID] = []
            for i in 0..<20 {
                let p = Player(firstName: firstNames[(i + idx) % firstNames.count], lastName: lastNames[(i * 2 + idx) % lastNames.count], age: Int.random(in: 18...33), nationality: ["France","Espagne","Italie","Portugal"][i % 4], position: positions[i], club: teamName, overall: 62 + Int.random(in: 0...20), potential: 68 + Int.random(in: 0...20), salary: Double.random(in: 12000...70000), estimatedValue: Double.random(in: 1_000_000...25_000_000), morale: Int.random(in: 55...95), fitness: Int.random(in: 55...95))
                players.append(p); ids.append(p.id)
            }
            let wageBill = players.filter { ids.contains($0.id) }.map(\.salary).reduce(0,+)
            teams.append(Team(name: teamName, country: "France", league: "Ligue Playground", budget: .init(global: 80_000_000, transfer: 20_000_000, wage: 3_000_000), reputation: 60 + idx * 4, playerIDs: ids, wageBill: wageBill, wageBudgetAvailable: max(0, 3_000_000 - wageBill)))
        }
        return (players, teams)
    }

    static func defaultCompetitions(teams: [Team]) -> [Competition] { [.init(name: "Ligue Playground", country: "France", type: .league, teamIDs: teams.map(\.id))] }

    static func defaultSeason(teams: [Team]) -> Season {
        var fixtures: [MatchFixture] = []
        let startDate = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 12)) ?? .now
        let teamIDs = teams.map(\.id)
        guard teamIDs.count >= 2, teamIDs.count % 2 == 0 else {
            return Season(yearLabel: "2026/2027", fixtures: fixtures, table: teams.map { RankingEntry(teamID: $0.id) })
        }

        var rotation = teamIDs
        let rounds = teamIDs.count - 1
        for round in 0..<rounds {
            let date = startDate.addingTimeInterval(Double(round) * 86400 * 7)
            for pair in 0..<(teamIDs.count / 2) {
                let home = rotation[pair]
                let away = rotation[rotation.count - 1 - pair]
                fixtures.append(.init(matchday: round + 1, homeTeamID: home, awayTeamID: away, date: date))
            }
            let fixed = rotation.removeFirst()
            let last = rotation.removeLast()
            rotation.insert(last, at: 0)
            rotation.insert(fixed, at: 0)
        }

        let firstLeg = fixtures
        for f in firstLeg {
            let secondDate = f.date.addingTimeInterval(Double(rounds) * 86400 * 7)
            fixtures.append(.init(matchday: f.matchday + rounds, homeTeamID: f.awayTeamID, awayTeamID: f.homeTeamID, date: secondDate))
        }

        return Season(yearLabel: "2026/2027", fixtures: fixtures.sorted { $0.matchday == $1.matchday ? $0.date < $1.date : $0.matchday < $1.matchday }, table: teams.map { RankingEntry(teamID: $0.id) })
    }
}
