import SwiftUI

struct CoachDashboardView: View {
    @EnvironmentObject var store: DataStore
    var team: Team? { store.teams.first { $0.id == store.currentCareer?.teamID } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Dashboard Entraîneur").font(.title2.bold())
                if let t = team { Text("Club: \(t.name)") }
                NavigationLink("Classement") { RankingView() }.buttonStyle(.borderedProminent)
                NavigationLink("Saison & calendrier") { SeasonView() }.buttonStyle(.bordered)
                NavigationLink("Lancer prochain match") { MatchSimulationView() }.buttonStyle(.borderedProminent)
            }.padding()
        }
    }
}
