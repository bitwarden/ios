import BitwardenResources
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
    @MainActor
    func test_appExtensionButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.appExtension)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .appExtensionTapped)
    }

    /// Updating the value of the default URI match type sends the `.defaultUriMatchTypeChanged` action.
    @MainActor
    func test_defaultUriMatchTypeChanged_updateValue() throws {
        processor.state.defaultUriMatchType = .host
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.defaultUriMatchDetection)
        try menuField.select(newValue: UriMatchType.exact)
        XCTAssertEqual(processor.dispatchedActions.last, .defaultUriMatchTypeChanged(.exact))
    }

    /// Tapping the password auto-fill button dispatches the `.passwordAutoFillTapped` action.
    @MainActor
    func test_passwordAutoFillButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.passwordAutofill)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .passwordAutoFillTapped)
    }

    /// The action card is hidden if the autofill setup progress is complete.
    @MainActor
    func test_setUpUnlockActionCard_hidden_complete() {
        processor.state.badgeState = .fixture(autofillSetupProgress: .complete)
        XCTAssertThrowsError(try subject.inspect().find(ActionCard<BitwardenBadge>.self))
    }

    /// The action card is hidden if there's no autofill setup progress.
    @MainActor
    func test_setUpUnlockActionCard_hidden_nilBadgeState() {
        processor.state.badgeState = nil
        XCTAssertThrowsError(try subject.inspect().find(ActionCard<BitwardenBadge>.self))
    }

    /// The action card is visible if the autofill setup progress isn't complete.
    @MainActor
    func test_setUpUnlockActionCard_visible() async throws {
        processor.state.badgeState = .fixture(autofillSetupProgress: .setUpLater)
        let actionCard = try subject.inspect().find(actionCard: Localizations.getStarted)

        let badge = try actionCard.find(BitwardenBadge.self)
        try XCTAssertEqual(badge.text().string(), "1")
    }

    /// Tapping the dismiss button in the set up autofill action card sends the
    /// `.dismissSetUpUnlockActionCard` effect.
    @MainActor
    func test_setUpUnlockActionCard_visible_tapDismiss() async throws {
        processor.state.badgeState = .fixture(autofillSetupProgress: .setUpLater)
        let actionCard = try subject.inspect().find(actionCard: Localizations.setUpAutofill)

        let button = try actionCard.find(asyncButton: Localizations.dismiss)
        try await button.tap()
        XCTAssertEqual(processor.effects, [.dismissSetUpAutofillActionCard])
    }

    /// Tapping the get started button in the set up autofill action card sends the
    /// `.showSetUpUnlock` action.
    @MainActor
    func test_setUpUnlockActionCard_visible_tapGetStarted() async throws {
        processor.state.badgeState = .fixture(autofillSetupProgress: .setUpLater)
        let actionCard = try subject.inspect().find(actionCard: Localizations.setUpAutofill)

        let button = try actionCard.find(asyncButton: Localizations.getStarted)
        try await button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.showSetUpAutofill])
    }

    // MARK: Snapshots

    /// The view renders correctly with the autofill action card is displayed.
    @MainActor
    func test_snapshot_actionCardAutofill() async {
        processor.state.badgeState = .fixture(autofillSetupProgress: .setUpLater)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The view renders correctly.
    @MainActor
    func test_view_render() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
