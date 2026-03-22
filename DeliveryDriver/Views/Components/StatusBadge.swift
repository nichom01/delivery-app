import SwiftUI

struct StatusBadge: View {
    enum Status: String {
        case pending   = "Pending"
        case completed = "Completed"
        case failed    = "Failed"
        case sent      = "Sent"

        var color: Color {
            switch self {
            case .pending:   return DS.Colors.warning
            case .completed: return DS.Colors.success
            case .failed:    return DS.Colors.error
            case .sent:      return DS.Colors.success
            }
        }
    }

    let status: Status

    var body: some View {
        Text(status.rawValue.uppercased())
            .font(DS.Typography.micro())
            .foregroundColor(.white)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(status.color)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.badge))
    }
}
