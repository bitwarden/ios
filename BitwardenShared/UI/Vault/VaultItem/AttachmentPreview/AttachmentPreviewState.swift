import BitwardenKit
@preconcurrency import BitwardenSdk
import Foundation

// MARK: - AttachmentPreviewContent

/// The content to display in an `AttachmentPreviewView`, based on the downloaded attachment.
enum AttachmentPreviewContent: Equatable, Hashable, Sendable {
    /// The attachment could not be decoded into a displayable image.
    case fileError

    /// The attachment is an image that decoded successfully, with its raw data.
    case image(Data)

    /// The attachment's file type isn't supported for in-app preview.
    case unsupportedFileType(fileExtension: String)
}

// MARK: - AttachmentPreviewState

/// An object that defines the current state of an `AttachmentPreviewView`.
///
struct AttachmentPreviewState: Equatable, Hashable, Sendable {
    // MARK: Properties

    /// The attachment being previewed.
    let attachment: AttachmentView

    /// The content to display for the attachment.
    var content: AttachmentPreviewContent

    /// The attachment's file name.
    let fileName: String

    /// The url where the decrypted attachment is temporarily stored.
    let temporaryUrl: URL

    /// A toast message to show in the view.
    var toast: Toast?

    // MARK: Computed Properties

    /// The file name, middle-truncated to fit the navigation bar title if necessary, always
    /// preserving the trailing file extension.
    var truncatedFileName: String {
        Self.truncateMiddle(fileName, maxLength: Self.maxTruncatedFileNameLength)
    }

    // MARK: Hashable, Equatable

    /// `toast` is transient view-only state and isn't part of this value's identity, so it's
    /// excluded here. This lets `AttachmentPreviewState` remain `Hashable`, which `VaultItemRoute`
    /// requires, even though `Toast` itself isn't `Hashable`.
    static func == (lhs: AttachmentPreviewState, rhs: AttachmentPreviewState) -> Bool {
        lhs.attachment == rhs.attachment
            && lhs.content == rhs.content
            && lhs.fileName == rhs.fileName
            && lhs.temporaryUrl == rhs.temporaryUrl
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(attachment)
        hasher.combine(content)
        hasher.combine(fileName)
        hasher.combine(temporaryUrl)
    }
}

// MARK: - Private

private extension AttachmentPreviewState {
    /// The maximum length, in characters, of the truncated file name shown in the navigation bar.
    static let maxTruncatedFileNameLength = 40

    /// Middle-truncates a string to `maxLength` characters, preserving the trailing file
    /// extension (if any).
    ///
    /// - Parameters:
    ///   - string: The string to truncate.
    ///   - maxLength: The maximum length of the returned string.
    /// - Returns: The truncated string, or the original string if it's already short enough.
    static func truncateMiddle(_ string: String, maxLength: Int) -> String {
        guard string.count > maxLength else { return string }

        let ellipsis = "…"
        let pathExtension = (string as NSString).pathExtension
        let extensionSuffix = pathExtension.isEmpty ? "" : ".\(pathExtension)"
        let name = extensionSuffix.isEmpty ? string : String(string.dropLast(extensionSuffix.count))

        let availableLength = maxLength - ellipsis.count - extensionSuffix.count
        guard availableLength > 0, name.count > availableLength else {
            return String(string.prefix(max(maxLength - ellipsis.count, 0))) + ellipsis
        }

        let headLength = (availableLength + 1) / 2
        let tailLength = availableLength / 2
        let head = name.prefix(headLength)
        let tail = name.suffix(tailLength)
        return "\(head)\(ellipsis)\(tail)\(extensionSuffix)"
    }
}
