// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

class MasterPasswordGuidanceViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<Void, MasterPasswordGuidanceAction, Void>!
    var subject: MasterPasswordGuidanceView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ())

        subject = MasterPasswordGuidanceView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the close button dispatches the `.dismiss` action.
    @MainActor
    func test_closeButton_tap() throws {
        let button = try subject.inspect().findCloseToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the password generator button dispatches the `.generatePasswordPressed` action.
    @MainActor
    func test_passwordGeneratorButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.checkOutThePassphraseGenerator)
        try await button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .generatePasswordPressed)
    }
}
