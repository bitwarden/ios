import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - PasswordAutoFillViewTests

class PasswordAutoFillViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PasswordAutoFillState, Void, PasswordAutoFillEffect>!
    var subject: PasswordAutoFillView!

    // MARK: Setup & Teardown

    override func setUp() {
        processor = MockProcessor(
            state: PasswordAutoFillState(
                mode: .settings,
                nativeCreateAccountFeatureFlag: false
            )
        )
        subject = PasswordAutoFillView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the turn on later button dispatches the `.turnAutoFillOnLaterTapped()` effect.
    @MainActor
    func test_turnOnAutoFillLaterButton_tap() async throws {
        processor.state.mode = .onboarding
        processor.state.nativeCreateAccountFeatureFlag = true
        let button = try subject.inspect().find(asyncButton: Localizations.turnOnLater)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .turnAutoFillOnLaterButtonTapped)
    }

    /// The button to turn on later doesn't exist when navigating in settings mode.
    @MainActor
    func test_turnOnAutoFillLaterButton_doesntExist() async throws {
        processor.state.mode = .settings
        processor.state.nativeCreateAccountFeatureFlag = true
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.turnOnLater))
    }

    /// The legacy view renders correctly.
    func test_view_render() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ]
        )
    }

    /// The view renders correctly with the feature flag on and mode set to onboarding.
    @MainActor
    func test_view_rendersWithFeatureFlag_withOnboardingMode() {
        processor.state.nativeCreateAccountFeatureFlag = true
        processor.state.mode = .onboarding

        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .portrait(heightMultiple: 1.2),
                .portraitDark(heightMultiple: 1.2),
                .tallPortraitAX5(heightMultiple: 2.2),
                .defaultLandscape,
            ]
        )
    }

    /// The view renders correctly with the feature flag on and mode set to settings.
    @MainActor
    func test_view_rendersWithFeatureFlag_withSettingsMode() {
        processor.state.nativeCreateAccountFeatureFlag = true
        processor.state.mode = .settings

        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .portrait(heightMultiple: 1.2),
                .portraitDark(heightMultiple: 1.2),
                .tallPortraitAX5(heightMultiple: 3),
                .defaultLandscape,
            ]
        )
    }
}
