import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    var body: some View {
        Group {
            if let career = store.currentCareer {
                switch career.role {
                case .coach: CoachDashboardView()
                case .sportingDirector: SportingDirectorDashboardView()
                case .president: PresidentDashboardView()
                }
            } else {
                Text("Créez une carrière d'abord")
            }
        }
    }
}
