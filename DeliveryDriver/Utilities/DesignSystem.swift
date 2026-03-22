import SwiftUI

// MARK: - Colour palette and typography constants for the Strava-inspired design language.

enum DS {
    enum Colors {
        static let background    = Color(hex: "#0D0D1A")
        static let surface       = Color(hex: "#1A1A2E")
        static let card          = Color(hex: "#1E2240")
        static let accent        = Color(hex: "#FF6B35")
        static let textPrimary   = Color.white
        static let textSecondary = Color(hex: "#8A8AA8")
        static let divider       = Color(hex: "#2A2A45")
        static let success       = Color(hex: "#4CAF50")
        static let warning       = Color(hex: "#FFC107")
        static let error         = Color(hex: "#F44336")
    }

    enum Typography {
        static func hero()       -> Font { .system(size: 36, weight: .black) }
        static func title()      -> Font { .system(size: 24, weight: .bold) }
        static func headline()   -> Font { .system(size: 18, weight: .bold) }
        static func body()       -> Font { .system(size: 16, weight: .regular) }
        static func bodyBold()   -> Font { .system(size: 16, weight: .semibold) }
        static func caption()    -> Font { .system(size: 13, weight: .medium) }
        static func micro()      -> Font { .system(size: 11, weight: .semibold) }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card:   CGFloat = 14
        static let button: CGFloat = 12
        static let badge:  CGFloat = 6
        static let input:  CGFloat = 10
    }
}

// MARK: - Hex colour initialiser

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Reusable view modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DS.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Typography.bodyBold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .background(configuration.isPressed || isLoading
                ? DS.Colors.accent.opacity(0.7)
                : DS.Colors.accent)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.button))
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
