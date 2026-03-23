import SwiftUI

struct DeliveryDetailView: View {
    @ObservedObject var delivery: DeliveryEntity

    // Fetch the POD for this delivery — auto-updates if one is submitted while the view is open.
    @FetchRequest private var pods: FetchedResults<PODEntity>

    init(delivery: DeliveryEntity) {
        self.delivery = delivery
        _pods = FetchRequest(
            entity: PODEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \PODEntity.capturedAt, ascending: false)],
            predicate: NSPredicate(format: "deliveryId == %@", delivery.deliveryId ?? "")
        )
    }

    private var capturedPOD: PODEntity? { pods.first }

    var body: some View {
        ZStack {
            DS.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    headerCard
                    addressCard
                    if hasInstructions { instructionsCard }

                    if let pod = capturedPOD {
                        PODPreviewView(pod: pod)
                    }

                    captureButton
                }
                .padding(DS.Spacing.md)
            }
        }
        .navigationTitle("Delivery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DS.Colors.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Cards

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(delivery.recipientName ?? "Unknown")
                        .font(DS.Typography.title())
                        .foregroundColor(DS.Colors.textPrimary)
                    Text(delivery.deliveryId ?? "")
                        .font(DS.Typography.caption())
                        .foregroundColor(DS.Colors.textSecondary)
                }
                Spacer()
                StatusBadge(status: badgeStatus)
            }

            Divider().background(DS.Colors.divider)

            HStack(spacing: DS.Spacing.xl) {
                metricView(value: "\(delivery.boxCount)", unit: "boxes", icon: "shippingbox.fill")
                metricView(value: String(format: "%.1f", delivery.weightKg), unit: "kg", icon: "scalemass.fill")
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }

    private var addressCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionLabel("Delivery Address", icon: "mappin.circle.fill")

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                if let a1 = delivery.address1, !a1.isEmpty { addressLine(a1) }
                if let a2 = delivery.address2, !a2.isEmpty { addressLine(a2) }
                if let city = delivery.city, !city.isEmpty {
                    addressLine([city, delivery.postcode].compactMap { $0 }.joined(separator: "  "))
                }
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionLabel("Special Instructions", icon: "exclamationmark.bubble.fill")
            Text(delivery.instructions ?? "")
                .font(DS.Typography.body())
                .foregroundColor(DS.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .background(DS.Colors.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.warning.opacity(0.4), lineWidth: 1)
        }
    }

    // Shows the capture CTA for pending deliveries; a greyed confirmation for completed ones.
    private var captureButton: some View {
        Group {
            if capturedPOD == nil {
                NavigationLink(destination: PODView(delivery: delivery)) {
                    Label("Capture Proof of Delivery", systemImage: "signature")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(delivery.status == "completed")
                .opacity(delivery.status == "completed" ? 0.4 : 1)
            } else {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(DS.Colors.success)
                    Text("POD already captured for this delivery.")
                        .font(DS.Typography.caption())
                        .foregroundColor(DS.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(DS.Spacing.md)
                .background(DS.Colors.success.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.button))
            }
        }
    }

    // MARK: - Helpers

    private func metricView(value: String, unit: String, icon: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(DS.Colors.accent)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(DS.Colors.textPrimary)
                Text(unit)
                    .font(DS.Typography.micro())
                    .foregroundColor(DS.Colors.textSecondary)
            }
        }
    }

    private func sectionLabel(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(DS.Typography.caption())
            .foregroundColor(DS.Colors.textSecondary)
    }

    private func addressLine(_ text: String) -> some View {
        Text(text)
            .font(DS.Typography.body())
            .foregroundColor(DS.Colors.textPrimary)
    }

    private var hasInstructions: Bool {
        !(delivery.instructions?.isEmpty ?? true)
    }

    private var badgeStatus: StatusBadge.Status {
        switch delivery.status {
        case "completed": return .completed
        case "failed":    return .failed
        default:          return .pending
        }
    }
}
