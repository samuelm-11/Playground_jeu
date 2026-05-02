import SwiftUI

struct TeamEditorView: View {
    @EnvironmentObject var store: DataStore
    var team: Team?
    @State private var name = ""
    @State private var country = "France"

    var body: some View {
        Form {
            TextField("Nom", text: $name)
            TextField("Pays", text: $country)
            Button("Enregistrer") { save() }
        }
        .onAppear {
            guard let t = team else { return }
            name = t.name; country = t.country
        }
    }

    private func save() {
        if let t = team, let idx = store.teams.firstIndex(where: { $0.id == t.id }) {
            store.teams[idx].name = name
            store.teams[idx].country = country
        } else {
            store.teams.append(.init(name: name, country: country, league: "Ligue Playground", budget: .init(global: 40_000_000, transfer: 8_000_000, wage: 2_000_000), reputation: 55, playerIDs: []))
        }
    }
}
