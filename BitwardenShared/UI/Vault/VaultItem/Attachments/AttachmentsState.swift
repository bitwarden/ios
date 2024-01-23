import BitwardenSdk
import Foundation

// MARK: - AttachmentsState

/// An object that defines the current state of a `AttachmentsView`.
///
struct AttachmentsState: Equatable {
    /// The cipher.
    var cipher: CipherView?

    /// The data for the selected file.
    var fileData: Data?

    /// The name of the selected file.
    var fileName: String?

    /// Whether the user has access to premium features.
    var hasPremium = false

    /// A toast message to show in the view.
    var toast: Toast?
}
