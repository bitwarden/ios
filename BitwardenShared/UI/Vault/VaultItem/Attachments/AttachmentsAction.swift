import UIKit

// MARK: - AttachmentsAction

/// Actions that can be processed by an `AttachmentsProcessor`.
///
enum AttachmentsAction: Equatable {
    /// The choose file button was pressed.
    case chooseFilePressed

    /// The dismiss button was pressed.
    case dismissPressed

    /// The camera view was dismissed.
    case cameraViewPresentedChanged(Bool)

    /// The user took a photo or selected an image.
    case imageChanged(UIImage?)
}
