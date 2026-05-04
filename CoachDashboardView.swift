import SwiftUI

struct CoachDashboardView: View {
    @EnvironmentObject var store: DataStore

    private let grid = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var team: Team? { store.teams.first { $0.id == store.currentCareer?.teamID } }
    var nextMatch: MatchFixture? { store.nextMatchForCareer() }
    var currentTeamID: UUID? { store.currentCareer?.teamID }
    var sortedTable: [RankingEntry] { store.season.table.sorted { $0.points == $1.points ? $0.goalDifference > $1.goalDifference : $0.points > $1.points } }
    var topScorer: Player? { store.players.max(by: { $0.stats.goals < $1.stats.goals }) }
    var topAssister: Player? { store.players.max(by: { $0.stats.assists < $1.stats.assists }) }
    var topRated: Player? { store.players.max(by: { $0.stats.averageRating < $1.stats.averageRating }) }
    var lineupPlayers: [Player] {
        let ids = Set(store.currentCareer?.selectedLineup ?? [])
        return store.players.filter { ids.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                DashboardCard(title: team?.name ?? "Club", subtitle: "Rôle: Entraîneur • Journée \(nextMatch?.matchday ?? 0)") {
                    Text("Préparez votre onze, vos choix tactiques et surveillez le marché avant le prochain match.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let m = nextMatch {
                    let isHome = m.homeTeamID == currentTeamID
                    let opponent = store.teamName(isHome ? m.awayTeamID : m.homeTeamID)
                    MatchPreviewCard(
                        title: "Prochain match",
                        details: "vs \(opponent) • \(m.date.formatted(date: .abbreviated, time: .omitted)) • \(isHome ? "Domicile" : "Extérieur")",
                        cta: "Jouer le match"
                    ) {
                        _ = store.simulateNextMatchdayForCareer()
                    }
                }

                NavigationLink {
                    RankingView()
                } label: {
                    DashboardCard(title: "Classement") {
                        RankingMiniWidget(rows: sortedTable, currentTeamID: currentTeamID, teamName: store.teamName)
                    }
                }.buttonStyle(.plain)

                LazyVGrid(columns: grid, spacing: 12) {
                    NavigationLink { TeamManagementView() } label: {
                        DashboardCard(title: "Gestion d'équipe") {
                            let fatigue = lineupPlayers.isEmpty ? 0 : lineupPlayers.map { 100 - $0.fitness }.reduce(0,+) / lineupPlayers.count
                            StatMiniCard(label: "Formation", value: store.currentCareer?.formation ?? "4-3-3")
                            StatMiniCard(label: "Mentalité", value: store.currentCareer?.tactic.rawValue ?? "Équilibré")
                            StatMiniCard(label: "Titulaires", value: "\(store.currentCareer?.selectedLineup.count ?? 0)/11")
                            StatMiniCard(label: "Fatigue moy.", value: "\(fatigue)%")
                        }
                    }.buttonStyle(.plain)

                    NavigationLink { ChampionshipStatsView() } label: {
                        DashboardCard(title: "Stats championnat") {
                            Text("Buteur: \(topScorer?.fullName ?? "-") (\(topScorer?.stats.goals ?? 0))").font(.caption)
                            Text("Passeur: \(topAssister?.fullName ?? "-") (\(topAssister?.stats.assists ?? 0))").font(.caption)
                            Text("Meilleure note: \(topRated?.fullName ?? "-") (\(String(format: "%.2f", topRated?.stats.averageRating ?? 0)))").font(.caption)
                        }
                    }.buttonStyle(.plain)

                    NavigationLink { TransferMarketView() } label: {
                        DashboardCard(title: "Marché transferts") {
                            Text("Budget: \(Int(team?.budget.transfer ?? 0))€").font(.caption)
                            Text("Shortlist: \(store.currentCareer?.shortlist.count ?? 0)").font(.caption)
                            Text("Offres rapides disponibles").font(.caption2).foregroundStyle(.secondary)
                        }
                    }.buttonStyle(.plain)

                    NavigationLink { ShortlistView() } label: {
                        DashboardCard(title: "Shortlist") {
                            Text("Joueurs suivis: \(store.currentCareer?.shortlist.count ?? 0)").font(.caption)
                            Text("Consulter les profils et faire une offre.").font(.caption2).foregroundStyle(.secondary)
                        }
                    }.buttonStyle(.plain)
                }

                NavigationLink {
                    TransferHistoryView()
                } label: {
                    DashboardCard(title: "Historique transferts", subtitle: "Toutes les offres et décisions") {
                        Text("Dernière entrée: \(latestTransferText)").font(.caption)
                    }
                }.buttonStyle(.plain)

                DashboardCard(title: "Actualités") {
                    if let news = store.currentCareer?.latestNews.prefix(4), !news.isEmpty {
                        ForEach(Array(news), id: \.self) { Text("• \($0)").font(.caption) }
                    } else {
                        Text("Dernier résultat, prochain adversaire et infos transfert apparaîtront ici.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Mode Entraîneur")
    }

    var latestTransferText: String {
        guard let last = store.transferHistory.first else { return "Aucun transfert enregistré" }
        let name = store.players.first(where: { $0.id == last.playerID })?.fullName ?? "Joueur"
        return "\(name) • \(last.accepted ? "Accepté" : "Refusé")"
    }
}

struct TeamManagementView: View {
    @EnvironmentObject var store: DataStore
    @State private var selected: Set<UUID> = []
    @State private var formation = "4-3-3"

    let formations = ["4-4-2", "4-3-3", "4-2-3-1", "3-5-2", "5-3-2"]

    var players: [Player] {
        guard let teamID = store.currentCareer?.teamID else { return [] }
        return store.teamPlayers(teamID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DashboardCard(title: "Résumé coaching", subtitle: "Formation + état de l'effectif") {
                    Picker("Formation", selection: $formation) {
                        ForEach(formations, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    Picker("Mentalité", selection: Binding(get: { store.currentCareer?.tactic ?? .balanced }, set: { store.setTactic($0) })) {
                        ForEach(Tactic.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    HStack {
                        StatMiniCard(label: "Formation", value: formation)
                        StatMiniCard(label: "Mentalité", value: store.currentCareer?.tactic.rawValue ?? "Équilibré")
                    }
                    HStack {
                        StatMiniCard(label: "Titulaires", value: "\(selected.count)/11")
                        StatMiniCard(label: "Fatigue moy.", value: "\(averageFatigue)%")
                    }
                }

                groupedSection(title: "Gardien", items: players.filter { $0.position == .gk })
                groupedSection(title: "Défense", items: players.filter { [.cb,.lb,.rb].contains($0.position) })
                groupedSection(title: "Milieu", items: players.filter { [.cm].contains($0.position) })
                groupedSection(title: "Attaque", items: players.filter { [.lw,.rw,.st].contains($0.position) })

                DashboardCard(title: "Banc des remplaçants") {
                    ForEach(players.filter { !selected.contains($0.id) }) { p in PlayerRowCard(player: p) }
                }

                DashboardCard(title: "Alertes composition") {
                    if selected.count < 11 { Text("⚠️ Moins de 11 titulaires").font(.caption) }
                    if selected.count > 11 { Text("⚠️ Trop de titulaires").font(.caption) }
                    if selectedPlayers.contains(where: { $0.fitness < 45 }) { Text("⚠️ Joueur très fatigué").font(.caption) }
                    if !isFormationCompatible { Text("⚠️ Composition non adaptée à la formation").font(.caption) }
                    if selected.count == 11 && isFormationCompatible && !selectedPlayers.contains(where: { $0.fitness < 45 }) { Text("✅ Composition prête").font(.caption) }
                }
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            selected = Set(store.currentCareer?.selectedLineup ?? [])
            formation = store.currentCareer?.formation ?? "4-3-3"
        }
        .onChange(of: selected) { store.setLineup(Array($0)) }
        .onChange(of: formation) { store.setFormation($0) }
        .navigationTitle("Gestion d'équipe")
    }

    var selectedPlayers: [Player] { players.filter { selected.contains($0.id) } }
    var averageFatigue: Int {
        guard !selectedPlayers.isEmpty else { return 0 }
        return selectedPlayers.map { 100 - $0.fitness }.reduce(0,+) / selectedPlayers.count
    }
    var isFormationCompatible: Bool {
        let stCount = selectedPlayers.filter { $0.position == .st }.count
        return formation == "4-4-2" ? stCount >= 2 : stCount >= 1
    }

    func groupedSection(title: String, items: [Player]) -> some View {
        DashboardCard(title: title) {
            ForEach(items) { p in
                Button {
                    if selected.contains(p.id) { selected.remove(p.id) }
                    else if selected.count < 11 { selected.insert(p.id) }
                } label: {
                    PlayerRowCard(player: p, trailing: AnyView(Text(selected.contains(p.id) ? "Titulaire" : "Banc").font(.caption)))
                }.buttonStyle(.plain)
            }
        }
    }
}
