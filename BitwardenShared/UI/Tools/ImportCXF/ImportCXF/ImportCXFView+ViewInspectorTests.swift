// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - ImportCXFViewTests

class ImportCXFViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ImportCXFState, Void, ImportCXFEffect>!
    var subject: ImportCXFView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ImportCXFState())
        let store = Store(processor: processor)

        subject = ImportCXFView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping on the continue button performs the `.mainButtonTapped` effect.
    @MainActor
    func test_mainButton_tapped() throws {
        processor.state.status = .start
        let button = try subject.inspect().find(button: Localizations.continue)
        try button.tap()
        waitFor {
            processor.effects.last == .mainButtonTapped
        }
    }

    /// Tapping on the cancel button performs the `.cancel` effect.
    @MainActor
    func test_cancelButton_tapped() throws {
        processor.state.status = .start
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        waitFor {
            processor.effects.last == .cancel
        }
    }
}
