import XCTest

@testable import BitwardenShared

// MARK: - MockUIDocumentPickerViewController

class MockUIDocumentPickerViewController: UIDocumentPickerViewController {
    // MARK: Properties

    var didDismiss = false

    // MARK: Initialization

    convenience init() {
        self.init(forOpeningContentTypes: [.data])
    }

    // MARK: Methods

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        didDismiss = true
    }
}
