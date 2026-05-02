import SwiftUI

struct DatabaseView: View {
    @EnvironmentObject var store: DataStore
    @State private var jsonPreview = ""

    var body: some View {
        List {
            Section("Joueurs") {
                NavigationLink("Ajouter joueur") { PlayerEditorView() }
                ForEach(store.players.prefix(20)) { p in
                    NavigationLink("\(p.fullName) - \(p.club)") { PlayerEditorView(player: p) }
                }
            }
            Section("Équipes") {
                NavigationLink("Ajouter équipe") { TeamEditorView() }
                ForEach(store.teams) { t in
                    NavigationLink(t.name) { TeamEditorView(team: t) }
                }
            }
            Section("Compétitions") {
                NavigationLink("Ajouter compétition") { CompetitionEditorView() }
                ForEach(store.competitions) { c in
                    NavigationLink(c.name) { CompetitionEditorView(competition: c) }
                }
            }
            Section("JSON") {
                Button("Exporter (aperçu)") { jsonPreview = store.exportJSON() }
                TextEditor(text: $jsonPreview).frame(height: 120)
                Button("Importer depuis l'aperçu") { store.importJSON(jsonPreview) }
            }
        }
        .navigationTitle("Base de données")
    }
}
