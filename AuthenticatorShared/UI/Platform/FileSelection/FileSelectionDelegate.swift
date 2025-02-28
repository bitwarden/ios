import Foundation

// MARK: - FileSelectionDelegate

/// A delegate object that responds to file selection events.
///
@MainActor
protocol FileSelectionDelegate: AnyObject {
    /// A file was chosen by the user.
    ///
    /// - Parameters:
    ///   - fileName: The name of the selected file.
    ///   - data: The data representation of the selected file.
    ///
    func fileSelectionCompleted(fileName: String, data: Data)
}
