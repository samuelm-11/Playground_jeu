import SwiftUI

struct ChampionshipStatsView: View {
    @EnvironmentObject var store: DataStore
    var players: [Player] { store.players }
    var body: some View {
        List {
            statSection("Buteurs", players.sorted{$0.stats.goals > $1.stats.goals}) { "\($0.stats.goals)" }
            statSection("Passeurs", players.sorted{$0.stats.assists > $1.stats.assists}) { "\($0.stats.assists)" }
            statSection("Notes", players.sorted{$0.stats.averageRating > $1.stats.averageRating}) { String(format: "%.2f", $0.stats.averageRating) }
            statSection("Temps de jeu", players.sorted{$0.stats.minutesPlayed > $1.stats.minutesPlayed}) { "\($0.stats.minutesPlayed) min" }
            statSection("Cartons", players.sorted{$0.stats.redCards > $1.stats.redCards}) { "J \($0.stats.yellowCards) | R \($0.stats.redCards)" }
        }.navigationTitle("Statistiques")
    }
    func statSection(_ title: String, _ sortedPlayers: [Player], value: @escaping (Player)->String) -> some View {
        Section(title) { ForEach(Array(sortedPlayers.prefix(10).enumerated()), id: \.element.id) { i,p in HStack { Text("#\(i+1)"); VStack(alignment:.leading){Text(p.fullName); Text("\(p.club) • \(p.position.rawValue)").font(.caption)}; Spacer(); Text(value(p)).bold() } } }
    }
}

struct PlayerDetailView: View {
    @EnvironmentObject var store: DataStore
    let player: Player
    @State private var amount = ""
    var body: some View { Form { Section("Identité"){Text(player.fullName);Text("\(player.age) ans - \(player.nationality)");Text("\(player.club) • \(player.position.rawValue)")}; Section("Niveau"){Text("Note \(player.overall)");Text("Potentiel \(player.potential)");Text("Valeur \(Int(player.estimatedValue))€");Text("Salaire \(Int(player.salary))€");Text("Moral \(player.morale) | Forme \(player.fitness)");Text("Contrat jusqu'en \(player.contractUntilYear)")}; Section("Stats"){Text("MJ \(player.stats.matchesPlayed) • Titu \(player.stats.starts)");Text("Buts \(player.stats.goals) • Passes \(player.stats.assists)");Text("Jaunes \(player.stats.yellowCards) • Rouges \(player.stats.redCards)")}; Button((store.currentCareer?.shortlist.contains(player.id) == true) ? "Retirer de la shortlist" : "Ajouter à la shortlist") { store.toggleShortlist(playerID: player.id) }; Section("Faire une offre"){TextField("Montant", text: $amount); Button("Envoyer") { _ = store.makeOffer(playerID: player.id, amount: Double(amount) ?? 0) }} }.navigationTitle("Fiche joueur") }
}

struct TransferMarketView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedPosition: Position?
    @State private var selectedTeam = "Tous"
    @State private var maxValue: Double = 100_000_000
    @State private var maxAge = 40
    var filtered: [Player] {
        store.players.filter { (selectedPosition == nil || $0.position == selectedPosition!) && (selectedTeam == "Tous" || $0.club == selectedTeam) && $0.estimatedValue <= maxValue && $0.age <= maxAge }
            .sorted { $0.overall > $1.overall }
    }
    var body: some View { VStack { Form { Picker("Poste", selection: $selectedPosition) { Text("Tous").tag(Position?.none); ForEach(Position.allCases){ Text($0.rawValue).tag(Position?.some($0)) } }; Picker("Équipe", selection: $selectedTeam){ Text("Tous").tag("Tous"); ForEach(store.teams.map(\.name), id:\.self){ Text($0).tag($0) } }; Stepper("Âge max: \(maxAge)", value: $maxAge, in: 16...40) ; Slider(value: $maxValue, in: 500_000...80_000_000, step: 500_000) { Text("Valeur") } } List(filtered){ p in NavigationLink(destination: PlayerDetailView(player: p)) { Text("\(p.fullName) | \(p.club) | \(p.position.rawValue) | GEN \(p.overall) | \(Int(p.estimatedValue))€") } } }.navigationTitle("Marché des transferts") }
}

struct TransferHistoryView: View {
    @EnvironmentObject var store: DataStore
    var body: some View { List(store.transferHistory) { t in VStack(alignment:.leading){ Text("\(store.players.first(where:{$0.id==t.playerID})?.fullName ?? "Joueur") - \(t.accepted ? "Accepté":"Refusé")"); Text("\(store.teamName(t.fromTeamID)) → \(store.teamName(t.toTeamID)) | \(Int(t.amount))€").font(.caption); Text(t.date.formatted(date: .abbreviated, time: .shortened)).font(.caption2) } }.navigationTitle("Historique transferts") }
}
