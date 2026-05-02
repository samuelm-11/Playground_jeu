import SwiftUI

struct RoleSelectionView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Choisissez votre rôle").font(.title2.bold())
            ForEach(Role.allCases) { role in
                NavigationLink(role.rawValue) { TeamSelectionView(selectedRole: role) }
                    .buttonStyle(.borderedProminent)
            }
            Spacer()
        }.padding()
    }
}
