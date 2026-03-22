import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            DS.Colors.background.ignoresSafeArea()

            VStack(spacing: DS.Spacing.lg) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(DS.Colors.accent)

                VStack(spacing: DS.Spacing.xs) {
                    Text("Delivery")
                        .font(DS.Typography.hero())
                        .foregroundColor(DS.Colors.textPrimary)
                    Text("Driver")
                        .font(DS.Typography.hero())
                        .foregroundColor(DS.Colors.accent)
                }

                ProgressView()
                    .tint(DS.Colors.accent)
                    .scaleEffect(1.4)
                    .padding(.top, DS.Spacing.lg)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                appState.checkSession()
            }
        }
    }
}
