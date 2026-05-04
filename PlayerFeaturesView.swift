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
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DashboardCard(title: "Profil") { Text(player.fullName); Text("\(player.age) ans - \(player.nationality)"); Text("\(player.club) • \(player.position.rawValue)") }
                DashboardCard(title: "Stats saison") { Text("MJ \(player.stats.matchesPlayed) • Buts \(player.stats.goals) • Passes \(player.stats.assists)"); Text("Note moy. \(String(format: "%.2f", player.stats.averageRating))") }
                DashboardCard(title: "Contrat") { Text("Salaire \(Int(player.salary))€"); Text("Valeur \(Int(player.estimatedValue))€"); Text("Jusqu'en \(player.contractUntilYear)") }

                DashboardCard(title: "Actions recrutement") {
                    PillButton(title: (store.currentCareer?.shortlist.contains(player.id) == true) ? "Retirer shortlist" : "Ajouter shortlist") { store.toggleShortlist(playerID: player.id) }
                    TextField("Montant de l'offre", text: $amount)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    PillButton(title: "Faire une offre", color: AppTheme.accent) {
                        feedback = store.makeOffer(playerID: player.id, amount: Double(amount) ?? 0)
                    }
                    if !feedback.isEmpty {
                        Text(feedback)
                            .foregroundStyle(feedback.contains("acceptée") ? AppTheme.success : (feedback.contains("insuffisant") ? AppTheme.danger : AppTheme.warning))
                            .font(.subheadline.bold())
                    }
                }
            }.padding()
        }.background(AppTheme.background.ignoresSafeArea()).navigationTitle("Fiche joueur")
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
        ScrollView {
            VStack(spacing: 12) {
                DashboardCard(title: "Filtres marché") {
                    TextField("Recherche par nom", text: $query)
                        .textFieldStyle(.roundedBorder)
                    Picker("Poste", selection: $selectedPosition) { Text("Tous").tag(Position?.none); ForEach(Position.allCases){ Text($0.rawValue).tag(Position?.some($0)) } }
                    Stepper("Âge max: \(maxAge)", value: $maxAge, in: 16...40)
                    VStack(alignment: .leading) {
                        Text("Valeur max: \(Int(maxValue))€").font(.caption)
                        Slider(value: $maxValue, in: 500_000...80_000_000, step: 500_000)
                    }
                    Picker("Tri", selection: $sort) { Text("Note").tag("Note"); Text("Potentiel").tag("Potentiel"); Text("Valeur").tag("Valeur") }
                }

                ForEach(filtered) { p in
                    NavigationLink(destination: PlayerDetailView(player: p)) {
                        DashboardCard(title: p.fullName, subtitle: "\(p.club) • \(p.position.rawValue)") {
                            HStack { StatMiniCard(label: "Âge", value: "\(p.age)"); StatMiniCard(label: "Note", value: "\(p.overall)"); StatMiniCard(label: "Pot.", value: "\(p.potential)") }
                            HStack { StatMiniCard(label: "Valeur", value: "\(Int(p.estimatedValue))€"); StatMiniCard(label: "Salaire", value: "\(Int(p.salary))€") }
                            HStack {
                                PillButton(title: "Shortlist") { store.toggleShortlist(playerID: p.id) }
                                Spacer()
                                Text("Voir fiche").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }.buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
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
    var body: some View {
        List(store.transferHistory) { t in
            VStack(alignment:.leading) {
                Text("\(store.players.first(where:{$0.id==t.playerID})?.fullName ?? "Joueur") - \(t.accepted ? "Accepté":"Refusé")")
                Text("\(store.teamName(t.fromTeamID)) → \(store.teamName(t.toTeamID)) | \(Int(t.amount))€").font(.caption)
                Text(t.date.formatted(date: .abbreviated, time: .shortened)).font(.caption2)
            }
        }.navigationTitle("Historique transferts")
    }
}
