import Foundation

// MARK: - AttachmentsState

/// An object that defines the current state of a `AttachmentsView`.
///
struct AttachmentsState: Equatable {
    /// The attachments.
    var attachments: [String] = []

    /// The data for the selected file.
    var fileData: Data?

    /// The name of the selected file.
    var fileName: String?
}
