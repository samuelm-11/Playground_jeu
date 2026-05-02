import SwiftUI

struct DashboardCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title, subtitle: subtitle)
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct StatMiniCard: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
        .padding(10)
        .background(AppTheme.cardAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct PlayerRowCard: View {
    let player: Player
    var trailing: AnyView? = nil
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.fullName).font(.headline)
                Text("\(player.position.rawValue) • \(player.age) ans • GEN \(player.overall)").font(.caption).foregroundStyle(.secondary)
                Text("Valeur \(Int(player.estimatedValue))€ • Salaire \(Int(player.salary))€").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if let trailing { trailing }
        }
        .padding(10)
        .background(AppTheme.cardAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct MatchPreviewCard: View {
    let title: String
    let details: String
    let cta: String
    let action: () -> Void
    var body: some View {
        DashboardCard(title: title) {
            Text(details).font(.subheadline)
            PillButton(title: cta, action: action)
        }
    }
}

struct RankingMiniWidget: View {
    let rows: [RankingEntry]
    let currentTeamID: UUID?
    let teamName: (UUID) -> String
    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(rows.prefix(5).enumerated()), id: \.element.id) { index, row in
                HStack {
                    Text("#\(index + 1)").font(.caption)
                    Text(teamName(row.teamID)).font(.caption)
                    Spacer()
                    Text("\(row.points) pts").font(.caption.bold())
                }
                .padding(6)
                .background((row.teamID == currentTeamID) ? AppTheme.accent.opacity(0.25) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.headline)
            if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
        }
    }
}

struct PillButton: View {
    let title: String
    var color: Color = AppTheme.accent
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.subheadline.bold()).padding(.horizontal, 14).padding(.vertical, 8)
                .background(color)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
    }
}
