import XCTest

@testable import AuthenticatorShared

// MARK: - MockFileSelectionDelegate

class MockFileSelectionDelegate: FileSelectionDelegate {
    // MARK: Properties

    var fileName: String?
    var data: Data?

    // MARK: Methods

    func fileSelectionCompleted(fileName: String, data: Data) {
        self.fileName = fileName
        self.data = data
    }
}
