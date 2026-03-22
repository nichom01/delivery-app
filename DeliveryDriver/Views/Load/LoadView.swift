import SwiftUI

struct LoadView: View {
    @StateObject private var vm = LoadViewModel()
    @State private var showManualEntry = false

    var body: some View {
        ZStack {
            DS.Colors.background.ignoresSafeArea()

            if !vm.hasManifest {
                noManifestState
            } else {
                scannerContent
            }
        }
        .onAppear { vm.checkManifest() }
    }

    // MARK: - No manifest guard

    private var noManifestState: some View {
        EmptyStateView(
            icon: "exclamationmark.triangle.fill",
            title: "No Manifest Downloaded",
            message: "Please go to the Manifest tab and download a manifest before loading parcels."
        )
    }

    // MARK: - Scanner content

    private var scannerContent: some View {
        ZStack {
            // Live camera feed
            BarcodeScannerView(
                onScan: { value in vm.handleScan(value) },
                isScanning: $vm.isScanning
            )
            .ignoresSafeArea()

            // Targeting overlay
            VStack {
                Spacer()
                scannerReticle
                Spacer()

                bottomControls
                    .padding(.bottom, DS.Spacing.xl)
            }

            // Confirmation overlay (appears after a successful scan)
            if let scan = vm.confirmedScan {
                confirmationOverlay(scan: scan)
            }
        }
    }

    private var scannerReticle: some View {
        ZStack {
            // Dim the surrounds
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .reverseMask {
                    RoundedRectangle(cornerRadius: 16)
                        .frame(width: 260, height: 160)
                }

            // Target box
            RoundedRectangle(cornerRadius: 16)
                .stroke(DS.Colors.accent, lineWidth: 3)
                .frame(width: 260, height: 160)

            Text("Align barcode within frame")
                .font(DS.Typography.caption())
                .foregroundColor(.white)
                .padding(.top, 170)
        }
    }

    private var bottomControls: some View {
        VStack(spacing: DS.Spacing.md) {
            Button {
                showManualEntry = true
            } label: {
                Label("Enter barcode manually", systemImage: "keyboard")
                    .font(DS.Typography.caption())
                    .foregroundColor(DS.Colors.textSecondary)
            }
        }
        .sheet(isPresented: $showManualEntry) {
            manualEntrySheet
        }
    }

    // MARK: - Manual entry sheet

    private var manualEntrySheet: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background.ignoresSafeArea()

                VStack(spacing: DS.Spacing.lg) {
                    DDTextField(
                        placeholder: "Barcode / label value",
                        text: $vm.manualEntry,
                        icon: "barcode"
                    )
                    .padding(.horizontal, DS.Spacing.lg)

                    if let error = vm.errorMessage {
                        Text(error)
                            .font(DS.Typography.caption())
                            .foregroundColor(DS.Colors.error)
                    }

                    Button("Submit") {
                        vm.submitManualEntry()
                        if vm.confirmedScan != nil { showManualEntry = false }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, DS.Spacing.lg)

                    Spacer()
                }
                .padding(.top, DS.Spacing.lg)
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showManualEntry = false }
                        .tint(DS.Colors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Confirmation overlay

    private func confirmationOverlay(scan: LoadViewModel.ScanConfirmation) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: DS.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(DS.Colors.success.opacity(0.2))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(DS.Colors.success)
                }

                VStack(spacing: DS.Spacing.sm) {
                    Text("Scanned")
                        .font(DS.Typography.headline())
                        .foregroundColor(DS.Colors.textPrimary)

                    Text(scan.barcodeValue)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(DS.Colors.accent)

                    Text(scan.timestamp.formatted(date: .omitted, time: .standard))
                        .font(DS.Typography.caption())
                        .foregroundColor(DS.Colors.textSecondary)
                }

                Button("Scan Next") {
                    vm.resumeScanning()
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 200)
            }
            .padding(DS.Spacing.xl)
            .background(DS.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .padding(.horizontal, DS.Spacing.xl)
        }
    }
}

// MARK: - Reverse mask helper

extension View {
    func reverseMask<Mask: View>(@ViewBuilder mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay {
                    mask()
                        .blendMode(.destinationOut)
                }
        }
    }
}
