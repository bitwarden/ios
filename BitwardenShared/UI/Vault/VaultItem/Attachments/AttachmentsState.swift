import UIKit

// MARK: - AttachmentsState

/// An object that defines the current state of a `AttachmentsView`.
///
struct AttachmentsState: Equatable {
    /// The attachments.
    var attachments: [String] = []

    /// Whether to show the camera view.
    var cameraViewPresented = false

    /// The image captured from the device's camera or photo library.
    var image: UIImage?
}
