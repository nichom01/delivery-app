import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60, weight: .thin))
                .foregroundColor(DS.Colors.accent)

            VStack(spacing: DS.Spacing.sm) {
                Text(title)
                    .font(DS.Typography.headline())
                    .foregroundColor(DS.Colors.textPrimary)

                Text(message)
                    .font(DS.Typography.body())
                    .foregroundColor(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 220)
            }
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
