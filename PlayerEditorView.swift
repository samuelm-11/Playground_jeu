import SwiftUI

struct PlayerEditorView: View {
    @EnvironmentObject var store: DataStore
    var player: Player?
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var club = ""
    @State private var overall = 70

    var body: some View {
        Form {
            TextField("Prénom", text: $firstName)
            TextField("Nom", text: $lastName)
            TextField("Club", text: $club)
            Stepper("Note: \(overall)", value: $overall, in: 40...99)
            Button("Enregistrer") { save() }
        }
        .onAppear {
            guard let p = player else { return }
            firstName = p.firstName; lastName = p.lastName; club = p.club; overall = p.overall
        }
    }

    private func save() {
        if let p = player, let idx = store.players.firstIndex(where: { $0.id == p.id }) {
            store.players[idx].firstName = firstName
            store.players[idx].lastName = lastName
            store.players[idx].club = club
            store.players[idx].overall = overall
        } else {
            store.players.append(.init(firstName: firstName, lastName: lastName, age: 22, nationality: "France", position: .cm, club: club, overall: overall, potential: overall + 5, salary: 15000, estimatedValue: 1_500_000, morale: 75, fitness: 80))
        }
    }
}
