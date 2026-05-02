import SwiftUI

struct RankingView: View {
    @EnvironmentObject var store: DataStore
    var body: some View {
        List(sorted, id: \.id) { e in
            HStack {
                Text(store.teamName(e.teamID)).frame(maxWidth: .infinity, alignment: .leading)
                Text("\(e.points) pts")
            }
        }
        .navigationTitle("Classement")
    }

    var sorted: [RankingEntry] { store.season.table.sorted { $0.points > $1.points } }
}
