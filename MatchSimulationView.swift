import SwiftUI

struct MatchSimulationView: View {
    @EnvironmentObject var store: DataStore
    @State private var minute = 0
    @State private var homeGoals = 0
    @State private var awayGoals = 0
    @State private var comments: [String] = []

    var fixture: MatchFixture? { store.season.fixtures.first { !$0.played } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let f = fixture {
                Text("\(store.teamName(f.homeTeamID)) vs \(store.teamName(f.awayTeamID))").font(.title3.bold())
                Text("Score: \(homeGoals)-\(awayGoals)")
                Text("Minute: \(minute)'")
                Button("Simuler le match") { simulate(fixture: f) }.buttonStyle(.borderedProminent)
                List(comments, id: \.self) { Text($0) }
            } else {
                Text("Aucun match restant")
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Simulation")
    }

    private func simulate(fixture: MatchFixture) {
        minute = 0; homeGoals = 0; awayGoals = 0; comments = ["Coup d'envoi"]
        let h = store.teams.first { $0.id == fixture.homeTeamID }!
        let a = store.teams.first { $0.id == fixture.awayTeamID }!
        let homePower = h.averageRating(players: store.players)
        let awayPower = a.averageRating(players: store.players)
        for m in stride(from: 10, through: 90, by: 10) {
            minute = m
            let event = Int.random(in: 0...5)
            switch event {
            case 0: comments.append("\(m)' Occasion pour \(store.teamName(Bool.random() ? h.id : a.id))")
            case 1:
                let homeChance = homePower + Double.random(in: -15...15)
                let awayChance = awayPower + Double.random(in: -15...15)
                if homeChance >= awayChance { homeGoals += 1; comments.append("\(m)' BUT \(h.name) !") }
                else { awayGoals += 1; comments.append("\(m)' BUT \(a.name) !") }
            case 2: comments.append("\(m)' Carton jaune")
            case 3: comments.append("\(m)' Blessure légère, le staff intervient")
            case 4: comments.append("\(m)' Changement de dynamique")
            default: break
            }
        }
        comments.append("90' Fin du match")
    }
}
