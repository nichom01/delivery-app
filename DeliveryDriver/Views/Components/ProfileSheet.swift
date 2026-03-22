import SwiftUI

struct ProfileSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background.ignoresSafeArea()

                VStack(spacing: DS.Spacing.xl) {
                    Circle()
                        .fill(DS.Colors.card)
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 36))
                                .foregroundColor(DS.Colors.accent)
                        }

                    Text("Delivery Driver")
                        .font(DS.Typography.headline())
                        .foregroundColor(DS.Colors.textPrimary)

                    Divider()
                        .background(DS.Colors.divider)

                    Button {
                        dismiss()
                        appState.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(DS.Typography.bodyBold())
                            .foregroundColor(DS.Colors.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.md)
                            .background(DS.Colors.error.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.button))
                    }
                    .padding(.horizontal, DS.Spacing.lg)

                    Spacer()
                }
                .padding(.top, DS.Spacing.xl)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(DS.Colors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
