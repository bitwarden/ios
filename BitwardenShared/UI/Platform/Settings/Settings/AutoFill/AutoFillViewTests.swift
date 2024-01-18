import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AutoFillViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AutoFillState, AutoFillAction, AutoFillEffect>!
    var subject: AutoFillView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AutoFillState())
        let store = Store(processor: processor)

        subject = AutoFillView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the app extension button dispatches the `.appExtensionTapped` action.
    func test_appExtensionButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.appExtension)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .appExtensionTapped)
    }

    /// Updating the value of the default URI match type sends the `.defaultUriMatchTypeChanged` action.
    func test_defaultUriMatchTypeChanged_updateValue() throws {
        processor.state.defaultUriMatchType = .host
        let menuField = try subject.inspect().find(settingsMenuField: Localizations.defaultUriMatchDetection)
        try menuField.select(newValue: UriMatchType.exact)
        XCTAssertEqual(processor.dispatchedActions.last, .defaultUriMatchTypeChanged(.exact))
    }

    /// Tapping the password auto-fill button dispatches the `.passwordAutoFillTapped` action.
    func test_passwordAutoFillButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.passwordAutofill)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .passwordAutoFillTapped)
    }

    // MARK: Snapshots

    /// The view renders correctly.
    func test_view_render() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
