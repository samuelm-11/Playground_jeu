import SwiftUI

struct MatchSimulationView: View {
    @EnvironmentObject var store: DataStore
    let fixtureID: UUID
    @State private var simulatedUserFixtureID: UUID?

    var fixture: MatchFixture? { store.season.fixtures.first { $0.id == fixtureID } }
    var simulatedMatchday: Int? { store.season.fixtures.first(where: { $0.id == simulatedUserFixtureID })?.matchday }
    var matchdayFixtures: [MatchFixture] {
        guard let day = simulatedMatchday else { return [] }
        return store.fixturesForMatchday(day)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if simulatedUserFixtureID == nil, let f = fixture {
                Text("Journée \(f.matchday)").font(.headline)
                Text(f.date.formatted(date: .long, time: .omitted))
                Text("\(store.teamName(f.homeTeamID)) vs \(store.teamName(f.awayTeamID))").font(.title3.bold())
                Button("Lancer prochain match") {
                    simulatedUserFixtureID = store.simulateNextMatchdayForCareer()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!store.canSimulateNextMatch())
            } else if let userID = simulatedUserFixtureID, let userMatch = store.season.fixtures.first(where: { $0.id == userID }) {
                Text("Résultats de la journée \(userMatch.matchday)").font(.title3.bold())
                Text("Votre match").font(.headline)
                Text("\(store.teamName(userMatch.homeTeamID)) \(userMatch.homeGoals)-\(userMatch.awayGoals) \(store.teamName(userMatch.awayTeamID))")
                List {
                    Section("Commentaires") {
                        ForEach(userMatch.comments, id: \.self) { Text($0) }
                    }
                    Section("Autres matchs") {
                        ForEach(matchdayFixtures.filter { $0.id != userID }) { f in
                            Text("\(store.teamName(f.homeTeamID)) \(f.homeGoals)-\(f.awayGoals) \(store.teamName(f.awayTeamID))")
                        }
                    }
                }
                NavigationLink("Retour au dashboard") { DashboardView() }.buttonStyle(.bordered)
            } else {
                Text("Aucune simulation possible.")
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Simulation")
    }
}
