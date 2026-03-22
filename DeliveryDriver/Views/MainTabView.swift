import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var showProfile = false

    var body: some View {
        TabView {
            AppScreen(title: "Load") {
                LoadView()
            } showProfile: { showProfile = true }
            .tabItem { Label("Load", systemImage: "barcode.viewfinder") }

            AppScreen(title: "Manifest") {
                ManifestView()
            } showProfile: { showProfile = true }
            .tabItem { Label("Manifest", systemImage: "list.bullet.rectangle.portrait") }

            AppScreen(title: "Audit") {
                AuditView()
            } showProfile: { showProfile = true }
            .tabItem { Label("Audit", systemImage: "clock.arrow.circlepath") }

            AppScreen(title: "Settings") {
                SettingsView()
            } showProfile: { showProfile = true }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(DS.Colors.accent)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showProfile) {
            ProfileSheet()
        }
        .onAppear {
            LocationService.shared.start()
            SyncService.shared.start()
        }
    }
}

// Wraps each tab in a NavigationStack with a consistent branded top bar.
private struct AppScreen<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    let showProfile: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background.ignoresSafeArea()
                content()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(DS.Colors.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "shippingbox.fill")
                            .foregroundColor(DS.Colors.accent)
                        Text("DeliveryDriver")
                            .font(DS.Typography.caption())
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: showProfile) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(DS.Colors.accent)
                    }
                }
            }
        }
    }
}
