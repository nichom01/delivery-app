import SwiftUI
import UIKit

struct PODPreviewView: View {
    let pod: PODEntity

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {

            // Header
            HStack {
                Label("Proof of Delivery", systemImage: "checkmark.seal.fill")
                    .font(DS.Typography.caption())
                    .foregroundColor(DS.Colors.textSecondary)
                Spacer()
                transmissionBadge
            }

            Divider().background(DS.Colors.divider)

            // Metadata
            HStack(spacing: DS.Spacing.xl) {
                metaItem(
                    icon: "person.fill",
                    label: "Signed by",
                    value: pod.recipientName ?? "—"
                )
                if let date = pod.capturedAt {
                    metaItem(
                        icon: "clock.fill",
                        label: "Captured",
                        value: date.formatted(date: .abbreviated, time: .shortened)
                    )
                }
            }

            // Signature
            signatureView

            // Photo (if captured)
            if let photoData = pod.photoImage,
               let photo = UIImage(data: photoData) {
                photoView(photo)
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.Colors.success.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.success.opacity(0.3), lineWidth: 1.5)
        }
    }

    // MARK: - Subviews

    private var signatureView: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text("Signature")
                .font(DS.Typography.micro())
                .foregroundColor(DS.Colors.textSecondary)

            Group {
                if let sigData = pod.signatureImage,
                   let sig = UIImage(data: sigData) {
                    Image(uiImage: sig)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.badge))
                } else {
                    Color.white
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.badge))
                        .overlay {
                            Text("No signature data")
                                .font(DS.Typography.caption())
                                .foregroundColor(DS.Colors.textSecondary)
                        }
                }
            }
        }
    }

    private func photoView(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text("Delivery Photo")
                .font(DS.Typography.micro())
                .foregroundColor(DS.Colors.textSecondary)

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.badge))
        }
    }

    private var transmissionBadge: some View {
        Group {
            if pod.submittedAt != nil {
                Label("Sent", systemImage: "checkmark.circle.fill")
                    .font(DS.Typography.micro())
                    .foregroundColor(DS.Colors.success)
            } else {
                Label("Pending sync", systemImage: "clock.fill")
                    .font(DS.Typography.micro())
                    .foregroundColor(DS.Colors.warning)
            }
        }
    }

    private func metaItem(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Label(label, systemImage: icon)
                .font(DS.Typography.micro())
                .foregroundColor(DS.Colors.textSecondary)
            Text(value)
                .font(DS.Typography.bodyBold())
                .foregroundColor(DS.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
