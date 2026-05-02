import SwiftUI

struct CompetitionEditorView: View {
    @EnvironmentObject var store: DataStore
    var competition: Competition?
    @State private var name = ""
    @State private var country = "France"
    @State private var type: CompetitionType = .league

    var body: some View {
        Form {
            TextField("Nom", text: $name)
            TextField("Pays", text: $country)
            Picker("Type", selection: $type) { ForEach(CompetitionType.allCases) { Text($0.rawValue).tag($0) } }
            Button("Enregistrer") { save() }
        }
        .onAppear {
            guard let c = competition else { return }
            name = c.name; country = c.country; type = c.type
        }
    }

    private func save() {
        if let c = competition, let idx = store.competitions.firstIndex(where: { $0.id == c.id }) {
            store.competitions[idx].name = name; store.competitions[idx].country = country; store.competitions[idx].type = type
        } else {
            store.competitions.append(.init(name: name, country: country, type: type, teamIDs: store.teams.map(\.id)))
        }
    }
}
