import SwiftUI

struct AuditView: View {
    @StateObject private var vm = AuditViewModel()

    var body: some View {
        VStack(spacing: 0) {
            filterPicker

            if vm.filteredEvents.isEmpty {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: noEventsTitle,
                    message: noEventsMessage
                )
            } else {
                eventList
            }
        }
        .onAppear { vm.loadEvents() }
    }

    // MARK: - Filter picker

    private var filterPicker: some View {
        Picker("Filter", selection: $vm.filter) {
            ForEach(AuditViewModel.AuditFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
    }

    // MARK: - Event list

    private var eventList: some View {
        ScrollView {
            LazyVStack(spacing: DS.Spacing.sm) {
                ForEach(vm.filteredEvents) { event in
                    AuditRowView(event: event)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
        }
        .refreshable { vm.loadEvents() }
    }

    // MARK: - Empty state strings

    private var noEventsTitle: String {
        switch vm.filter {
        case .all:     return "No Events Yet"
        case .pending: return "Nothing Pending"
        case .sent:    return "Nothing Sent Yet"
        }
    }

    private var noEventsMessage: String {
        switch vm.filter {
        case .all:     return "Scans, PODs, and location pings will appear here once recorded."
        case .pending: return "All recorded events have been transmitted successfully."
        case .sent:    return "No events have been transmitted yet."
        }
    }
}

// MARK: - Row

private struct AuditRowView: View {
    let event: AuditEvent

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            // Type icon
            ZStack {
                Circle()
                    .fill(Color(hex: event.type.accentColor).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: event.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: event.type.accentColor))
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack {
                    Text(event.type.label.uppercased())
                        .font(DS.Typography.micro())
                        .foregroundColor(DS.Colors.textSecondary)
                    Spacer()
                    transmissionBadge
                }

                Text(event.description)
                    .font(DS.Typography.bodyBold())
                    .foregroundColor(DS.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(DS.Colors.textSecondary)
                    Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(DS.Typography.micro())
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }

    private var transmissionBadge: some View {
        Group {
            if event.isPending {
                Label("Pending", systemImage: "clock.fill")
                    .font(DS.Typography.micro())
                    .foregroundColor(DS.Colors.warning)
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(DS.Colors.warning.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Label("Sent", systemImage: "checkmark.circle.fill")
                        .font(DS.Typography.micro())
                        .foregroundColor(DS.Colors.success)

                    if let sent = event.submittedAt {
                        Text(sent.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 10))
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
            }
        }
    }
}
