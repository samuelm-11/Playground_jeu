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
                Section("Journée \(day)") {
                    ForEach(fixtures) { f in
                        let isUserClub = f.homeTeamID == store.currentCareer?.teamID || f.awayTeamID == store.currentCareer?.teamID
                        VStack(alignment: .leading) {
                            Text("\(store.teamName(f.homeTeamID)) vs \(store.teamName(f.awayTeamID))")
                                .fontWeight(isUserClub ? .bold : .regular)
                            Text(f.played ? "✅ \(f.homeGoals)-\(f.awayGoals)" : "🕒 \(f.date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("Saison \(store.season.yearLabel)")
    }
}
