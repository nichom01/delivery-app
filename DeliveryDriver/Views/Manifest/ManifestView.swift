import SwiftUI
import CoreData

struct ManifestView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var vm = ManifestViewModel()

    @FetchRequest(
        entity: DeliveryEntity.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \DeliveryEntity.status, ascending: true),
            NSSortDescriptor(keyPath: \DeliveryEntity.recipientName, ascending: true)
        ]
    ) private var deliveries: FetchedResults<DeliveryEntity>

    var body: some View {
        Group {
            if deliveries.isEmpty && !vm.isDownloading {
                EmptyStateView(
                    icon: "list.bullet.rectangle.portrait",
                    title: "No Manifest",
                    message: "Tap Download to fetch your deliveries for today.",
                    actionTitle: "Download Manifest"
                ) {
                    Task { await vm.downloadManifest() }
                }
            } else {
                deliveryList
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if vm.isDownloading {
                    ProgressView().tint(DS.Colors.accent)
                } else {
                    Button {
                        Task { await vm.downloadManifest() }
                    } label: {
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(DS.Colors.accent)
                    }
                }
            }
        }
        .alert("Download Failed", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    private var deliveryList: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let ts = vm.lastDownloadedAt {
                    lastUpdatedBanner(ts)
                }

                statsBar

                LazyVStack(spacing: DS.Spacing.sm) {
                    ForEach(deliveries) { delivery in
                        NavigationLink(destination: DeliveryDetailView(delivery: delivery)) {
                            DeliveryRowView(delivery: delivery)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.bottom, DS.Spacing.lg)
            }
        }
        .refreshable {
            await vm.downloadManifest()
        }
    }

    private func lastUpdatedBanner(_ date: Date) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(DS.Colors.success)
                .font(.system(size: 13))
            Text("Updated \(date.formatted(.relative(presentation: .named)))")
                .font(DS.Typography.caption())
                .foregroundColor(DS.Colors.textSecondary)
            Spacer()
            Text("\(deliveries.count) stops")
                .font(DS.Typography.caption())
                .foregroundColor(DS.Colors.textSecondary)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(DS.Colors.surface)
    }

    private var statsBar: some View {
        let pending   = deliveries.filter { $0.status == "pending" }.count
        let completed = deliveries.filter { $0.status == "completed" }.count

        return HStack(spacing: DS.Spacing.md) {
            statChip(value: "\(pending)",   label: "Pending",   color: DS.Colors.warning)
            statChip(value: "\(completed)", label: "Completed", color: DS.Colors.success)
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
    }

    private func statChip(value: String, label: String, color: Color) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(color)
            Text(label)
                .font(DS.Typography.caption())
                .foregroundColor(DS.Colors.textSecondary)
        }
    }
}

// MARK: - Row

private struct DeliveryRowView: View {
    @ObservedObject var delivery: DeliveryEntity

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            // Colour strip
            RoundedRectangle(cornerRadius: 3)
                .fill(statusColor)
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack {
                    Text(delivery.recipientName ?? "Unknown Recipient")
                        .font(DS.Typography.bodyBold())
                        .foregroundColor(DS.Colors.textPrimary)
                    Spacer()
                    StatusBadge(status: badgeStatus)
                }

                Text(addressSummary)
                    .font(DS.Typography.caption())
                    .foregroundColor(DS.Colors.textSecondary)
                    .lineLimit(1)

                HStack(spacing: DS.Spacing.sm) {
                    Label("\(delivery.boxCount) boxes", systemImage: "shippingbox")
                        .font(DS.Typography.micro())
                        .foregroundColor(DS.Colors.textSecondary)

                    Text("·")
                        .foregroundColor(DS.Colors.divider)

                    Label(String(format: "%.1f kg", delivery.weightKg), systemImage: "scalemass")
                        .font(DS.Typography.micro())
                        .foregroundColor(DS.Colors.textSecondary)

                    Text(delivery.deliveryId ?? "")
                        .font(DS.Typography.micro())
                        .foregroundColor(DS.Colors.divider)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }

    private var addressSummary: String {
        [delivery.address1, delivery.city, delivery.postcode]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: ", ")
    }

    private var badgeStatus: StatusBadge.Status {
        switch delivery.status {
        case "completed": return .completed
        case "failed":    return .failed
        default:          return .pending
        }
    }

    private var statusColor: Color {
        switch delivery.status {
        case "completed": return DS.Colors.success
        case "failed":    return DS.Colors.error
        default:          return DS.Colors.warning
        }
    }
}
