import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: DataStore
    var body: some View {
        VStack(spacing: 16) {
            Text("Football Manager Lite")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            NavigationLink("Nouvelle carrière") { RoleSelectionView() }
                .buttonStyle(.borderedProminent)
            NavigationLink("Charger carrière") {
                if store.currentCareer != nil { DashboardView() } else { Text("Aucune carrière sauvegardée") }
            }.buttonStyle(.bordered)
            NavigationLink("Base de données") { DatabaseView() }
                .buttonStyle(.bordered)
            Spacer()
        }
        .padding()
    }
}
