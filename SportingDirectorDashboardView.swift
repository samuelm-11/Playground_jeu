import SwiftUI

struct SportingDirectorDashboardView: View {
    @EnvironmentObject var store: DataStore
    var team: Team? { store.teams.first { $0.id == store.currentCareer?.teamID } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dashboard Directeur Sportif").font(.title2.bold())
            if let t = team {
                Text("Budget transfert: \(Int(t.budget.transfer))€")
                Text("Besoins: Renforcer la défense et trouver un BU jeune")
                Text("Contrats: 4 joueurs fin de contrat")
                Text("Transferts: 2 cibles suivies")
            }
            NavigationLink("Base de données joueurs") { DatabaseView() }
            Spacer()
        }.padding()
    }
}
