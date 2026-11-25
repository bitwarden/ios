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

    /// The name of the selected file, including its extension.
    var fileName: String?

    /// The extension of the selected file, including the leading period, or an empty string if the
    /// file has no extension. This can't be changed by the user when renaming the file.
    var fileNameExtension = ""

    /// The name of the selected file without its extension. This is the part of the file name the
    /// user can edit.
    var fileNameStem: String {
        String(fileName?.dropLast(fileNameExtension.count) ?? "")
    }

    /// Whether the user has access to Premium features.
    var hasPremium = false

    /// A toast message to show in the view.
    var toast: Toast?

    /// The URL to open in the device's web browser.
    var url: URL?
}
