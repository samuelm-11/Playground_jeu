import SwiftUI

struct SeasonView: View {
    @EnvironmentObject var store: DataStore

    var grouped: [(Int,[MatchFixture])] {
        Dictionary(grouping: store.season.fixtures, by: { $0.matchday })
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.sorted { $0.date < $1.date }) }
    }

    var body: some View {
        List {
            ForEach(grouped, id: \.0) { day, fixtures in
                Section("Journée \(day) — \(fixtures.first?.date.formatted(date: .abbreviated, time: .omitted) ?? "")") {
                    ForEach(fixtures) { f in
                        VStack(alignment: .leading) {
                            Text("\(store.teamName(f.homeTeamID)) vs \(store.teamName(f.awayTeamID))")
                            Text(f.played ? "✅ Joué (\(f.homeGoals)-\(f.awayGoals))" : "🕒 À venir")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("Saison \(store.season.yearLabel)")
    }
}
