import Foundation

// MARK: - FileUploadType

/// The enumeration of various file uploads methods.
///
enum FileUploadType: Int, Codable, Equatable {
    /// Upload directly to the server hosting the user's vault.
    case direct = 0

    /// Upload to an Azure enviornment.
    case azure = 1
}
