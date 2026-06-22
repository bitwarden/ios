import BitwardenKit
@preconcurrency import BitwardenSdk
import Foundation

// MARK: - AttachmentsState

/// An object that defines the current state of a `AttachmentsView`.
///
struct AttachmentsState: Equatable, Sendable {
    /// The cipher.
    var cipher: CipherView?

    /// The data for the selected file.
    var fileData: Data?

    /// The name of the selected file.
    var fileName: String?

    /// Whether the user has access to Premium features.
    var hasPremium = false

    /// A toast message to show in the view.
    var toast: Toast?

    /// The URL to open in the device's web browser.
    var url: URL?
}
