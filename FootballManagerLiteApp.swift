import SwiftUI

@main
struct FootballManagerLiteApp: App {
    @StateObject private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environmentObject(store)
        }
    }
}
