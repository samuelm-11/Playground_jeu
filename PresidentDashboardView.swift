import SwiftUI

struct PresidentDashboardView: View {
    @EnvironmentObject var store: DataStore
    var team: Team? { store.teams.first { $0.id == store.currentCareer?.teamID } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dashboard Président").font(.title2.bold())
            if let t = team {
                Text("Budget global: \(Int(t.budget.global))€")
                Text("Réputation du club: \(t.reputation)")
                Text("Objectifs: Top 4, masse salariale maîtrisée")
                Text("Décisions: Extension du stade (prototype)")
            }
            NavigationLink("Classement") { RankingView() }
            Spacer()
        }.padding()
    }
}
