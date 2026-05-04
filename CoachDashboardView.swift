import SwiftUI

struct CoachDashboardView: View {
    @EnvironmentObject var store: DataStore
    var nextMatch: MatchFixture? { store.nextMatchForCareer() }
    var body: some View {
        ScrollView { VStack(spacing: 12) {
            DashboardCard(title: "Confiance du board") { Text("\(store.currentCareer?.board.satisfaction ?? 0)% • \(store.currentCareer?.board.comment ?? "-")").font(.caption); NavigationLink("Voir board", destination: BoardView()) }
            DashboardCard(title: "Journal du jour") { ForEach(Array((store.currentCareer?.newsFeed ?? []).prefix(3))) { n in Text("• [\(n.source)] \(n.title)").font(.caption) }; NavigationLink("Toutes les actualités", destination: NewsFeedView()) }
            if let m = nextMatch { NavigationLink(destination: MatchSimulationView(fixtureID: m.id)) { MatchPreviewCard(title: "Prochain match", details: "\(store.teamName(m.homeTeamID)) vs \(store.teamName(m.awayTeamID))", cta: "Ouvrir Match Center"){} }.buttonStyle(.plain) }
            NavigationLink("Gestion d'équipe", destination: TeamManagementView())
            NavigationLink("Classement", destination: RankingView())
            NavigationLink("Stats championnat", destination: ChampionshipStatsView())
            NavigationLink("Marché transferts", destination: TransferMarketView())
            NavigationLink("Historique transferts", destination: TransferHistoryView())
        }.padding() }
        .navigationTitle("Mode Entraîneur")
    }
}

struct TeamManagementView: View {
    @EnvironmentObject var store: DataStore
    @State private var selected: Set<UUID> = []
    @State private var formation = "4-3-3"
    let formations = ["4-4-2", "4-3-3", "4-2-3-1", "3-5-2", "5-3-2"]
    var players: [Player] { store.teamPlayers(store.currentCareer?.teamID ?? UUID()) }
    var starters:[Player]{ players.filter{selected.contains($0.id)} }
    var body: some View {
        ScrollView { VStack(spacing:12){
            DashboardCard(title:"Résumé coaching"){ Picker("Formation",selection:$formation){ForEach(formations,id:\.self){Text($0)}}.pickerStyle(.segmented)
                Picker("Mentalité", selection: Binding(get:{store.currentCareer?.tactic ?? .balanced}, set:{store.setTactic($0)})){ForEach(Tactic.allCases){Text($0.rawValue).tag($0)}}.pickerStyle(.segmented)
            }
            TacticalPitchView(players: starters, formation: formation)
            DashboardCard(title:"Joueurs"){ ForEach(players){ p in HStack{ PlayerRowCard(player:p); Button(selected.contains(p.id) ? "Banc" : "Titulariser"){ if p.status == .available { if selected.contains(p.id){selected.remove(p.id)} else if selected.count < 11 {selected.insert(p.id)} } }.buttonStyle(.bordered) } } }
            DashboardCard(title:"Alertes composition"){ if selected.count<11{Text("⚠️ moins de 11 titulaires")}; if selected.count==11{Text("✅ composition valide")}; if starters.contains(where:{$0.fitness<45}){Text("⚠️ joueur très fatigué")}; if starters.contains(where:{$0.status != .available}){Text("⚠️ joueur indisponible")}}
        }.padding() }
        .onAppear{ selected=Set(store.currentCareer?.selectedLineup ?? []); formation=store.currentCareer?.formation ?? "4-3-3" }
        .onChange(of:selected){ store.setLineup(Array($0)) }
        .onChange(of:formation){ store.setFormation($0) }
    }
}

struct TacticalPitchView: View {
    let players: [Player]; let formation: String
    var body: some View { DashboardCard(title:"Terrain tactique visuel", subtitle: formation){ GeometryReader{geo in ZStack{ RoundedRectangle(cornerRadius: 16).fill(Color.green.opacity(0.25)); ForEach(Array(players.prefix(11).enumerated()), id:\.element.id){ idx,p in let y = CGFloat((idx%4)+1)/5; let x = CGFloat((idx/4)+1)/4; VStack{ Text(p.shortName).font(.caption2.bold()); Text("\(p.position.rawValue) • \(p.overall)").font(.caption2); Text("Fit \(p.fitness)").font(.caption2)}.padding(6).background(.white.opacity(0.9)).clipShape(RoundedRectangle(cornerRadius:8)).position(x:geo.size.width*y, y:geo.size.height*x) } } }.frame(height:260) } }
}

struct BoardView: View { @EnvironmentObject var store: DataStore; var body: some View { ScrollView{ DashboardCard(title:"Board", subtitle:"Satisfaction \(store.currentCareer?.board.satisfaction ?? 0)%"){ Text(store.currentCareer?.board.comment ?? "-"); ForEach(store.currentCareer?.board.objectives ?? []){ o in ProgressView(o.title, value:o.progress) }; Text("Risque: \(store.currentCareer?.board.riskLevel ?? "-")") }.padding() }.navigationTitle("Board") } }

struct NewsFeedView: View { @EnvironmentObject var store: DataStore; var body: some View { List(store.currentCareer?.newsFeed ?? []) { n in VStack(alignment:.leading){ Text(n.title).font(.headline); Text("\(n.source) • \(n.category.rawValue)").font(.caption).foregroundStyle(.secondary) } }.navigationTitle("Actualités") } }
