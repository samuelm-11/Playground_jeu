import SwiftUI

struct ChampionshipStatsView: View {
    @EnvironmentObject var store: DataStore
    var players: [Player] { store.players }
    var body: some View {
        List {
            statSection("Buteurs", players.sorted{$0.stats.goals > $1.stats.goals}) { "\($0.stats.goals)" }
            statSection("Passeurs", players.sorted{$0.stats.assists > $1.stats.assists}) { "\($0.stats.assists)" }
            statSection("Notes", players.sorted{$0.stats.averageRating > $1.stats.averageRating}) { String(format: "%.2f", $0.stats.averageRating) }
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
    @State private var feedback = ""
    var body: some View {
        Form {
            Section("Profil") { Text(player.fullName); Text("\(player.age) ans - \(player.nationality)"); Text("\(player.club) • \(player.position.rawValue)") }
            Section("Stats saison") { Text("MJ \(player.stats.matchesPlayed) • Buts \(player.stats.goals) • Passes \(player.stats.assists)"); Text("Note moy. \(String(format: "%.2f", player.stats.averageRating))") }
            Section("Contrat") { Text("Salaire \(Int(player.salary))€"); Text("Valeur \(Int(player.estimatedValue))€"); Text("Jusqu'en \(player.contractUntilYear)") }
            Button((store.currentCareer?.shortlist.contains(player.id) == true) ? "Retirer de la shortlist" : "Ajouter à la shortlist") { store.toggleShortlist(playerID: player.id) }
            Section("Faire une offre") {
                TextField("Montant", text: $amount)
                Button("Envoyer") { feedback = store.makeOffer(playerID: player.id, amount: Double(amount) ?? 0) }
                if !feedback.isEmpty { Text(feedback).foregroundStyle(feedback.contains("acceptée") ? .green : .orange) }
            }
        }.navigationTitle("Fiche joueur")
    }
}

struct TransferMarketView: View {
    @EnvironmentObject var store: DataStore
    @State private var query = ""
    @State private var selectedPosition: Position?
    @State private var maxValue: Double = 100_000_000
    @State private var maxAge = 40
    @State private var sort = "Note"

    var filtered: [Player] {
        let base = store.players.filter {
            (query.isEmpty || $0.fullName.localizedCaseInsensitiveContains(query)) &&
            (selectedPosition == nil || $0.position == selectedPosition!) &&
            $0.estimatedValue <= maxValue && $0.age <= maxAge
        }
        switch sort {
        case "Potentiel": return base.sorted { $0.potential > $1.potential }
        case "Valeur": return base.sorted { $0.estimatedValue < $1.estimatedValue }
        default: return base.sorted { $0.overall > $1.overall }
        }
    }

    var body: some View {
        VStack {
            Form {
                TextField("Recherche par nom", text: $query)
                Picker("Poste", selection: $selectedPosition) { Text("Tous").tag(Position?.none); ForEach(Position.allCases){ Text($0.rawValue).tag(Position?.some($0)) } }
                Stepper("Âge max: \(maxAge)", value: $maxAge, in: 16...40)
                Slider(value: $maxValue, in: 500_000...80_000_000, step: 500_000) { Text("Valeur max") }
                Picker("Tri", selection: $sort) { Text("Note").tag("Note"); Text("Potentiel").tag("Potentiel"); Text("Valeur").tag("Valeur") }
            }
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filtered) { p in
                        NavigationLink(destination: PlayerDetailView(player: p)) {
                            PlayerRowCard(player: p, trailing: AnyView(VStack { Button("Shortlist") { store.toggleShortlist(playerID: p.id) }.font(.caption2); Text("Voir fiche").font(.caption2).foregroundStyle(.secondary) }))
                        }.buttonStyle(.plain)
                    }
                }.padding(.horizontal)
            }
        }
        .navigationTitle("Marché des transferts")
    }
}

struct ShortlistView: View {
    @EnvironmentObject var store: DataStore
    var players: [Player] {
        let ids = Set(store.currentCareer?.shortlist ?? [])
        return store.players.filter { ids.contains($0.id) }
    }
    var body: some View {
        List(players) { p in
            NavigationLink(destination: PlayerDetailView(player: p)) { PlayerRowCard(player: p) }
        }
        .navigationTitle("Shortlist")
    }
}

struct TransferHistoryView: View {
    @EnvironmentObject var store: DataStore
    var body: some View { List(store.transferHistory) { t in VStack(alignment:.leading){ Text("\(store.players.first(where:{$0.id==t.playerID})?.fullName ?? "Joueur") - \(t.accepted ? "Accepté":"Refusé")"); Text("\(store.teamName(t.fromTeamID)) → \(store.teamName(t.toTeamID)) | \(Int(t.amount))€").font(.caption); Text(t.date.formatted(date: .abbreviated, time: .shortened)).font(.caption2) } }.navigationTitle("Historique transferts") }
}
