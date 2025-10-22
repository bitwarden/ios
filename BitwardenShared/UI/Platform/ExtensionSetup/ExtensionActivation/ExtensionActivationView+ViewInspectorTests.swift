// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

// MARK: - ExtensionActivationViewTests

class ExtensionActivationViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<
        ExtensionActivationState,
        ExtensionActivationAction,
        ExtensionActivationEffect,
    >!
    var subject: ExtensionActivationView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ExtensionActivationState(extensionType: .autofillExtension))
        let store = Store(processor: processor)

        subject = ExtensionActivationView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the back to settings dispatches the `.cancelTapped` action.
    @MainActor
    func test_backToSettingsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.backToSettings)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .cancelTapped)
    }
}
