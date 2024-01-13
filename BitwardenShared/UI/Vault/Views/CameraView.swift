import SwiftUI

// MARK: - CameraView

/// A view that allows the user to use the camera to capture images.
///
struct CameraView: UIViewControllerRepresentable {
    // MARK: Properties

    /// Whether the view is presented or not.
    @Environment(\.presentationMode) var isPresented

    /// The image result selected by the user
    @Binding var selectedImage: UIImage?

    // MARK: Methods

    /// Create the camera picker view.
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = context.coordinator
        return imagePicker
    }

    /// Create the coordinator used to pass the selected image to the caller.
    func makeCoordinator() -> Coordinator { Coordinator(cameraView: self) }

    /// A required delegate method that isn't used.
    func updateUIViewController(_: UIImagePickerController, context _: Context) {}
}

// MARK: - Coordinator

extension CameraView {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        // MARK: Properties

        /// The camera view.
        var cameraView: CameraView

        // MARK: Initialization

        /// Initializes a `CameraView.Coordinator`.
        ///
        /// - Parameter cameraView: The camera view.
        ///
        init(cameraView: CameraView) {
            self.cameraView = cameraView
        }

        // MARK: Methods

        /// Pass the captured image back to the caller and dismiss the camera view.
        func imagePickerController(
            _: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let selectedImage = info[.originalImage] as? UIImage else { return }
            cameraView.selectedImage = selectedImage
            cameraView.isPresented.wrappedValue.dismiss()
        }
    }
}
