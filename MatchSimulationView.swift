import SwiftUI

struct MatchSimulationView: View {
    @EnvironmentObject var store: DataStore
    let fixtureID: UUID

    var fixture: MatchFixture? { store.season.fixtures.first { $0.id == fixtureID } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let f = fixture {
                Text("Journée \(f.matchday)").font(.headline)
                Text(f.date.formatted(date: .long, time: .omitted))
                Text("\(store.teamName(f.homeTeamID)) vs \(store.teamName(f.awayTeamID))").font(.title3.bold())
                Text("Score: \(f.homeGoals)-\(f.awayGoals)")
                Text(f.played ? "Statut: Joué" : "Statut: À venir")
                if !f.played {
                    Button("Simuler le match") { store.simulateMatch(f.id) }.buttonStyle(.borderedProminent)
                }
                List(f.comments, id: \.self) { Text($0) }
                NavigationLink("Retour au dashboard") { DashboardView() }.buttonStyle(.bordered)
            } else { Text("Match introuvable") }
            Spacer()
        }
        .padding()
        .navigationTitle("Simulation")
    }
}
