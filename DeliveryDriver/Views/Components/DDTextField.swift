import SwiftUI

struct DDTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DS.Colors.textSecondary)
                .frame(width: 22)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            .foregroundColor(DS.Colors.textPrimary)
            .tint(DS.Colors.accent)
        }
        .padding(DS.Spacing.md)
        .background(DS.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.input))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.input)
                .stroke(DS.Colors.divider, lineWidth: 1)
        }
    }
}
