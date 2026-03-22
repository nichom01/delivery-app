import UIKit
import SwiftUI

// UIView that captures touch input and renders it as a smooth bezier path.
final class SignatureDrawingView: UIView {
    private var completedPaths: [UIBezierPath] = []
    private var currentPath: UIBezierPath?
    var onChange: (() -> Void)?

    var isEmpty: Bool { completedPaths.isEmpty && currentPath == nil }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        isMultipleTouchEnabled = false
    }
    required init?(coder: NSCoder) { fatalError() }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let pt = touches.first?.location(in: self) else { return }
        let path = UIBezierPath()
        path.lineWidth = 2.5
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: pt)
        currentPath = path
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let pt = touches.first?.location(in: self) else { return }
        currentPath?.addLine(to: pt)
        setNeedsDisplay()
        onChange?()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let path = currentPath { completedPaths.append(path) }
        currentPath = nil
        setNeedsDisplay()
        onChange?()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    override func draw(_ rect: CGRect) {
        UIColor.black.setStroke()
        completedPaths.forEach { $0.stroke() }
        currentPath?.stroke()
    }

    func clear() {
        completedPaths.removeAll()
        currentPath = nil
        setNeedsDisplay()
        onChange?()
    }

    func renderToImage() -> UIImage? {
        guard !isEmpty else { return nil }
        return UIGraphicsImageRenderer(bounds: bounds).image { _ in
            UIColor.white.setFill()
            UIRectFill(bounds)
            UIColor.black.setStroke()
            completedPaths.forEach { $0.stroke() }
            currentPath?.stroke()
        }
    }
}

// Class-based controller — safe to mutate from makeUIView without triggering
// a SwiftUI state-during-render warning.
final class SignatureCanvasController: ObservableObject {
    @Published var hasSignature = false
    fileprivate(set) weak var drawingView: SignatureDrawingView?

    func clear() {
        drawingView?.clear()
    }

    func renderImage() -> UIImage? {
        drawingView?.renderToImage()
    }
}

// SwiftUI wrapper.
struct SignatureCanvasView: UIViewRepresentable {
    @ObservedObject var controller: SignatureCanvasController

    func makeUIView(context: Context) -> SignatureDrawingView {
        let view = SignatureDrawingView()
        // Assigning to a class property here is safe — no @State mutation.
        controller.drawingView = view
        view.onChange = { [weak view, weak controller] in
            DispatchQueue.main.async {
                controller?.hasSignature = !(view?.isEmpty ?? true)
            }
        }
        return view
    }

    func updateUIView(_ uiView: SignatureDrawingView, context: Context) {}
}
