import SwiftUI

struct CoachDashboardView: View {
    @EnvironmentObject var store: DataStore
    var team: Team? { store.teams.first { $0.id == store.currentCareer?.teamID } }
    var nextMatch: MatchFixture? { store.nextMatchForCareer() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Dashboard Entraîneur").font(.title2.bold())
                if let t = team { Text("Club: \(t.name)") }
                if let m = nextMatch {
                    Text("Prochain match: J\(m.matchday) - \(store.teamName(m.homeTeamID)) vs \(store.teamName(m.awayTeamID))")
                } else { Text("Saison terminée") }

                if let news = store.currentCareer?.latestNews, !news.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Actualités").font(.headline)
                        ForEach(news, id: \.self) { Text("• \($0)").font(.caption) }
                    }
                }

                NavigationLink("Gestion d'équipe") { TeamManagementView() }.buttonStyle(.bordered)
                NavigationLink("Classement") { RankingView() }.buttonStyle(.borderedProminent)
                NavigationLink("Saison & calendrier") { SeasonView() }.buttonStyle(.bordered)
                if let m = nextMatch {
                    NavigationLink("Lancer prochain match") { MatchSimulationView(fixtureID: m.id) }
                        .buttonStyle(.borderedProminent)
                        .disabled(!store.canSimulateNextMatch())
                    if !store.canSimulateNextMatch() { Text("Sélectionnez 11 titulaires pour simuler").font(.caption).foregroundStyle(.red) }
                }
            }.padding()
        }
    }
}

struct TeamManagementView: View {
    @EnvironmentObject var store: DataStore
    @State private var selected: Set<UUID> = []

    var body: some View {
        let teamID = store.currentCareer?.teamID
        let players = teamID == nil ? [] : store.teamPlayers(teamID!)
        Form {
            Section("Tactique") {
                Picker("Style", selection: Binding(get: { store.currentCareer?.tactic ?? .balanced }, set: { store.setTactic($0) })) {
                    ForEach(Tactic.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
            }
            Section("Composition (11 titulaires)") {
                Text("Sélectionnés: \(selected.count)/11")
                ForEach(players) { p in
                    Button("\(selected.contains(p.id) ? "✅" : "⬜️") \(p.fullName) - \(p.position.rawValue) | Fatigue \(100 - p.fitness)%") {
                        if selected.contains(p.id) { selected.remove(p.id) }
                        else if selected.count < 11 { selected.insert(p.id) }
                        store.setLineup(Array(selected))
                    }
                }
            }
            Section("Effectif") {
                ForEach(players) { p in
                    VStack(alignment: .leading) {
                        Text("\(p.fullName) | \(p.position.rawValue) | \(p.age) ans | GEN \(p.overall) | Forme \(p.fitness) | Moral \(p.morale)")
                        if selected.contains(p.id) && p.fitness < 45 {
                            Text("⚠️ Titulaire fatigué: pensez à la rotation").font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .onAppear { selected = Set(store.currentCareer?.selectedLineup ?? []) }
        .navigationTitle("Gestion d'équipe")
    }
}
