import SwiftUI
import UIKit

// Wraps UIImagePickerController to support both camera capture and photo
// library selection (library is used as the fallback in the simulator where
// the camera is unavailable).
struct CameraPickerView: UIViewControllerRepresentable {
    enum Source {
        case camera
        case library
    }

    let source: Source
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false

        let requestedSource: UIImagePickerController.SourceType =
            source == .camera ? .camera : .photoLibrary

        // Fall back to photo library if the requested source isn't available
        // (e.g. camera on simulator).
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(requestedSource)
            ? requestedSource
            : .photoLibrary

        if picker.sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImage: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImage = onImage
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
