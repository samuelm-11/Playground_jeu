import SwiftUI

struct SeasonView: View {
    @EnvironmentObject var store: DataStore
    var body: some View {
        List(store.season.fixtures) { f in
            VStack(alignment: .leading) {
                Text("\(store.teamName(f.homeTeamID)) vs \(store.teamName(f.awayTeamID))")
                Text(f.played ? "Joué" : "À jouer")
            }
        }
        .navigationTitle("Saison \(store.season.yearLabel)")
    }
}
