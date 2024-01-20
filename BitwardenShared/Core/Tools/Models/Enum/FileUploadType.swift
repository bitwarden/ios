import Foundation

// MARK: - FileUploadType

/// The enumeration of various file uploads methods.
///
enum FileUploadType: Int, Codable, Equatable {
    case direct = 0
    case azure = 1
}
