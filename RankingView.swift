import SwiftUI

struct RankingView: View {
    @EnvironmentObject var store: DataStore
    var sorted: [RankingEntry] {
        store.season.table.sorted {
            if $0.points != $1.points { return $0.points > $1.points }
            if $0.goalDifference != $1.goalDifference { return $0.goalDifference > $1.goalDifference }
            return $0.goalsFor > $1.goalsFor
        }
    }

    var body: some View {
        List(Array(sorted.enumerated()), id: \.element.id) { idx, e in
            VStack(alignment: .leading) {
                Text("\(idx+1). \(store.teamName(e.teamID)) - \(e.points) pts")
                Text("J:\(e.played) V:\(e.wins) N:\(e.draws) D:\(e.losses) BP:\(e.goalsFor) BC:\(e.goalsAgainst) Diff:\(e.goalDifference)")
                    .font(.caption)
            }
        }
        .navigationTitle("Classement")
    }
}
