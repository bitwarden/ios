import Foundation

/// The state for the file share test screen.
///
struct FileShareState: Equatable {
    // MARK: Static Properties

    /// The content written to the sample file.
    static let sampleFileContent = "This is a sample file for testing Bitwarden Send file sharing."

    /// The name of the sample file written to the temporary directory.
    static let sampleFileName = "bitwarden-sample.txt"

    // MARK: Properties

    /// The URL of the sample file written to the temporary directory, once available.
    var shareableFileURL: URL?

    /// The text content to share via the iOS share sheet.
    var textContent: String = "Sample text to share via Bitwarden Send."

    /// The title of the screen.
    var title: String = Localizations.fileShare
}
