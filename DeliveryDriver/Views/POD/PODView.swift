import SwiftUI

struct PODView: View {
    @ObservedObject var delivery: DeliveryEntity
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: PODViewModel
    @StateObject private var canvas = SignatureCanvasController()
    @State private var showSuccess = false
    @State private var showPhotoPicker = false
    @State private var photoSource: CameraPickerView.Source = .camera

    init(delivery: DeliveryEntity) {
        self.delivery = delivery
        _vm = StateObject(wrappedValue: PODViewModel(delivery: delivery))
    }

    var body: some View {
        ZStack {
            DS.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    recipientField
                    signatureSection
                    photoSection
                    if let error = vm.errorMessage { inlineError(error) }
                    actionButtons
                }
                .padding(DS.Spacing.md)
            }
        }
        .navigationTitle("Proof of Delivery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DS.Colors.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(vm.isSubmitting)
        .overlay {
            if showSuccess { successOverlay }
        }
    }

    // MARK: - Sections

    private var recipientField: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionLabel("Recipient Name", icon: "person.fill")
            DDTextField(
                placeholder: "Recipient name",
                text: $vm.recipientName,
                icon: "person"
            )
        }
    }

    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                sectionLabel("Signature", icon: "signature")
                Spacer()
                Button("Clear") { canvas.clear() }
                    .font(DS.Typography.caption())
                    .foregroundColor(canvas.hasSignature ? DS.Colors.accent : DS.Colors.textSecondary)
                    .disabled(!canvas.hasSignature)
            }

            ZStack(alignment: .center) {
                SignatureCanvasView(controller: canvas)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.Radius.card)
                            .stroke(
                                canvas.hasSignature ? DS.Colors.accent.opacity(0.5) : DS.Colors.divider,
                                lineWidth: 1.5
                            )
                    }

                if !canvas.hasSignature {
                    Text("Draw signature here")
                        .font(DS.Typography.body())
                        .foregroundColor(DS.Colors.textSecondary)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                sectionLabel("Delivery Photo", icon: "camera.fill")
                Text("Optional")
                    .font(DS.Typography.micro())
                    .foregroundColor(DS.Colors.textSecondary)
                    .padding(.horizontal, DS.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(DS.Colors.surface)
                    .clipShape(Capsule())
                Spacer()
                if vm.capturedPhoto != nil {
                    Button("Retake") {
                        photoSource = .camera
                        showPhotoPicker = true
                    }
                    .font(DS.Typography.caption())
                    .foregroundColor(DS.Colors.accent)
                }
            }

            if let photo = vm.capturedPhoto {
                // Thumbnail of the captured photo
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            vm.capturedPhoto = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                        .padding(DS.Spacing.sm)
                    }
            } else {
                // Capture prompt
                Button {
                    photoSource = UIImagePickerController.isSourceTypeAvailable(.camera)
                        ? .camera : .library
                    showPhotoPicker = true
                } label: {
                    HStack(spacing: DS.Spacing.md) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(DS.Colors.accent)

                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text("Add a photo")
                                .font(DS.Typography.bodyBold())
                                .foregroundColor(DS.Colors.textPrimary)
                            Text(UIImagePickerController.isSourceTypeAvailable(.camera)
                                 ? "Take a photo of the delivered parcel"
                                 : "Choose from your photo library")
                                .font(DS.Typography.caption())
                                .foregroundColor(DS.Colors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                    .padding(DS.Spacing.md)
                    .cardStyle()
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            CameraPickerView(source: photoSource) { image in
                vm.capturedPhoto = image
                showPhotoPicker = false
            } onCancel: {
                showPhotoPicker = false
            }
            .ignoresSafeArea()
        }
    }

    private var actionButtons: some View {
        let nameEmpty = vm.recipientName.trimmingCharacters(in: .whitespaces).isEmpty
        let canSubmit = canvas.hasSignature && !nameEmpty && !vm.isSubmitting

        return VStack(spacing: DS.Spacing.sm) {
            Button {
                guard let image = canvas.renderImage() else { return }
                Task {
                    await vm.submit(signature: image) {
                        withAnimation { showSuccess = true }
                    }
                }
            } label: {
                Group {
                    if vm.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Label("Submit POD", systemImage: "checkmark.seal.fill")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle(isLoading: vm.isSubmitting))
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.5)

            if !canvas.hasSignature {
                Text("A signature is required to submit.")
                    .font(DS.Typography.micro())
                    .foregroundColor(DS.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Success overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: DS.Spacing.lg) {
                ZStack {
                    Circle().fill(DS.Colors.success.opacity(0.2)).frame(width: 90, height: 90)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 52))
                        .foregroundColor(DS.Colors.success)
                }

                VStack(spacing: DS.Spacing.xs) {
                    Text("POD Captured")
                        .font(DS.Typography.title())
                        .foregroundColor(DS.Colors.textPrimary)
                    Text("Delivery marked as completed.")
                        .font(DS.Typography.body())
                        .foregroundColor(DS.Colors.textSecondary)
                }

                Button("Back to Manifest") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: 240)
            }
            .padding(DS.Spacing.xl)
            .background(DS.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .padding(.horizontal, DS.Spacing.xl)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(DS.Typography.caption())
            .foregroundColor(DS.Colors.textSecondary)
    }

    private func inlineError(_ message: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DS.Colors.error)
            Text(message)
                .font(DS.Typography.caption())
                .foregroundColor(DS.Colors.error)
        }
        .padding(DS.Spacing.sm)
        .background(DS.Colors.error.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.badge))
    }
}
