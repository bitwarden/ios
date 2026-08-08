// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

class SelfHostedViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SelfHostedState, SelfHostedAction, SelfHostedEffect>!
    var subject: SelfHostedView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SelfHostedState())

        subject = SelfHostedView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// Tapping the add header button dispatches the `.addHeaderTapped` action.
    @MainActor
    func test_addHeaderButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.addHeader)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addHeaderTapped)
    }

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Updating the header name field dispatches the `.headerNameChanged` action.
    @MainActor
    func test_headerNameField_updated() throws {
        let field = SelfHostedState.CustomHeaderField()
        processor.state.customHeaders = [field]

        let textField = try subject.inspect().find(bitwardenTextField: Localizations.name)
        try textField.inputBinding().wrappedValue = "X-Access-Token"

        XCTAssertEqual(
            processor.dispatchedActions.last,
            .headerNameChanged(id: field.id, name: "X-Access-Token"),
        )
    }

    /// Updating the header value field dispatches the `.headerValueChanged` action.
    @MainActor
    func test_headerValueField_updated() throws {
        let field = SelfHostedState.CustomHeaderField(isValueVisible: true)
        processor.state.customHeaders = [field]

        let textField = try subject.inspect().find(bitwardenTextField: Localizations.value)
        try textField.inputBinding().wrappedValue = "test-secret"

        XCTAssertEqual(
            processor.dispatchedActions.last,
            .headerValueChanged(id: field.id, value: "test-secret"),
        )
    }

    /// Tapping the header value visibility toggle dispatches the `.headerValueVisibilityChanged`
    /// action.
    @MainActor
    func test_headerValueVisibilityToggle_tap() throws {
        let field = SelfHostedState.CustomHeaderField()
        processor.state.customHeaders = [field]

        let button = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.passwordIsNotVisibleTapToShow,
        )
        try button.tap()

        XCTAssertEqual(
            processor.dispatchedActions.last,
            .headerValueVisibilityChanged(id: field.id, isVisible: true),
        )
    }

    /// Tapping the remove header button dispatches the `.removeHeaderTapped` action.
    @MainActor
    func test_removeHeaderButton_tap() throws {
        let field = SelfHostedState.CustomHeaderField(name: "X-Access-Token", value: "test-secret")
        processor.state.customHeaders = [field]

        let button = try subject.inspect().find(button: Localizations.removeHeader)
        try button.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .removeHeaderTapped(id: field.id))
    }

    /// Tapping the save button dispatches the `.saveEnvironment` action.
    @MainActor
    func test_saveButton_tap() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-26079 Remove when toolbar AsyncButton is used.
            throw XCTSkip("Remove this when the toolbar save button gets updated to use AsyncButton.")
        }

        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .saveEnvironment)
    }
}
