import SwiftUI
import AVFoundation

// UIView subclass that owns the capture session and preview layer.
final class ScannerUIView: UIView {
    var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    func configure(session: AVCaptureSession) {
        self.session = session
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }
}

// SwiftUI wrapper around AVCaptureSession for barcode/QR scanning.
struct BarcodeScannerView: UIViewRepresentable {
    let onScan: (String) -> Void
    @Binding var isScanning: Bool

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    func makeUIView(context: Context) -> ScannerUIView {
        let view = ScannerUIView()
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return view
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return view }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
        output.metadataObjectTypes = [.ean13, .ean8, .qr, .code128, .code39, .upce, .dataMatrix]

        view.configure(session: session)
        context.coordinator.session = session

        if isScanning {
            DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
        }
        return view
    }

    func updateUIView(_ uiView: ScannerUIView, context: Context) {
        guard let session = uiView.session else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if self.isScanning, !session.isRunning { session.startRunning() }
            if !self.isScanning, session.isRunning { session.stopRunning() }
        }
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onScan: (String) -> Void
        var session: AVCaptureSession?
        private var lastScanned: String?

        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = obj.stringValue,
                  value != lastScanned else { return }
            lastScanned = value
            // Brief debounce — reset after 2 s so the same code can be rescanned.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.lastScanned = nil
            }
            onScan(value)
        }
    }
}
