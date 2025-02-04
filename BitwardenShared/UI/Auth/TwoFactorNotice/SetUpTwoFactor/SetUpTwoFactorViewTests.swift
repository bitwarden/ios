import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - SetUpTwoFactorViewTests

class SetUpTwoFactorViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SetUpTwoFactorState, SetUpTwoFactorAction, SetUpTwoFactorEffect>!
    var subject: SetUpTwoFactorView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SetUpTwoFactorState(allowDelay: true, emailAddress: "person@example.com"))
        let store = Store(processor: processor)

        subject = SetUpTwoFactorView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the change email button sends `.changeAccountEmailTapped`
    @MainActor
    func test_changeEmail_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.changeAccountEmail)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .changeAccountEmailTapped)
    }

    /// Tapping the remind me later button sends `.remindMeLater`
    @MainActor
    func test_remindMeLater_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.remindMeLater)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .remindMeLaterTapped)
    }

    /// Tapping the turn on two-step login button sends `.turnOnTwoFactorTapped`
    @MainActor
    func test_turnOnTwoStep_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.turnOnTwoStepLogin)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .turnOnTwoFactorTapped)
    }

    // MARK: Previews

    /// The set up two factor view renders correctly when delay is allowed
    @MainActor
    func test_snapshot_setUpTwoFactorView_allowDelay_true() {
        processor.state.allowDelay = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape]
        )
    }

    /// The set up two factor view renders correctly when delay is not allowed
    @MainActor
    func test_snapshot_setUpTwoFactorView_allowDelay_false() {
        processor.state.allowDelay = false
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape]
        )
    }
}
