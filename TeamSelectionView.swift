import SwiftUI

struct TeamSelectionView: View {
    @EnvironmentObject var store: DataStore
    let selectedRole: Role

    var body: some View {
        List(store.teams) { team in
            NavigationLink {
                DashboardView()
                    .onAppear { store.createCareer(role: selectedRole, teamID: team.id) }
            } label: {
                VStack(alignment: .leading) {
                    Text(team.name).font(.headline)
                    Text("Budget transfert: \(Int(team.budget.transfer))€")
                }
            }
        }
        .navigationTitle("Choix du club")
    }
}
