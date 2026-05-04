import SwiftUI

struct MatchSimulationView: View {
    @EnvironmentObject var store: DataStore
    let fixtureID: UUID

    var fixture: MatchFixture? { store.season.fixtures.first { $0.id == fixtureID } }
    var report: MatchCenterReport? { store.currentCareer?.lastMatchReport?.fixtureID == fixtureID ? store.currentCareer?.lastMatchReport : nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let f = fixture {
                    DashboardCard(title: "Match Center", subtitle: "Journée \(f.matchday)") {
                        Text("\(store.teamName(f.homeTeamID)) \(f.homeGoals) - \(f.awayGoals) \(store.teamName(f.awayTeamID))").font(.title.bold())
                        Text(statusText(f)).font(.caption)
                        Button("Lancer le match") { _ = store.simulateNextMatchdayForCareer() }.buttonStyle(.borderedProminent).disabled(f.played || !store.canSimulateNextMatch())
                    }
                    if let r = report {
                        DashboardCard(title: "Timeline") { ForEach(r.events) { Text($0.text).font(.caption) } }
                        DashboardCard(title: "Statistiques") {
                            if let h = r.homeStats, let a = r.awayStats {
                                statRow("Possession", "\(h.possession)%", "\(a.possession)%"); statRow("Tirs", "\(h.shots)", "\(a.shots)"); statRow("Cadrés", "\(h.shotsOnTarget)", "\(a.shotsOnTarget)")
                                statRow("Fautes", "\(h.fouls)", "\(a.fouls)"); statRow("xG", String(format:"%.2f", h.xg), String(format:"%.2f", a.xg))
                            }
                        }
                        DashboardCard(title: "Homme du match") { Text(store.players.first(where:{$0.id == r.playerOfTheMatchID})?.fullName ?? "-") }
                        DashboardCard(title: "Notes joueurs") { ForEach(r.ratings.sorted(by:{$0.rating > $1.rating})) { e in Text("\(store.players.first(where:{$0.id==e.playerID})?.shortName ?? "Joueur") • \(String(format:"%.1f", e.rating))").font(.caption) } }
                    }
                }
            }.padding()
        }.navigationTitle("Match Center")
    }
    func statRow(_ n:String,_ l:String,_ r:String)->some View { HStack{ Text(l).frame(width:50); Spacer(); Text(n).font(.caption); Spacer(); Text(r).frame(width:50) } }
    func statusText(_ f: MatchFixture) -> String { f.played ? "Terminé" : "Avant-match" }
}
