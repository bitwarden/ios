// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
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
            ),
        )
        subject = PasswordAutoFillView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// The legacy view renders correctly.
    func disabletest_snapshot_view_render() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ],
        )
    }

    /// The view renders correctly with the mode set to onboarding.
    @MainActor
    func disabletest_snapshot_view_renders_withOnboardingMode() {
        processor.state.mode = .onboarding

        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .portrait(heightMultiple: 1.2),
                .portraitDark(heightMultiple: 1.2),
                .tallPortraitAX5(heightMultiple: 2.2),
                .defaultLandscape,
            ],
        )
    }

    /// The view renders correctly with mode set to settings.
    @MainActor
    func disabletest_snapshot_view_renders_withSettingsMode() {
        processor.state.mode = .settings

        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .portrait(heightMultiple: 1.2),
                .portraitDark(heightMultiple: 1.2),
                .tallPortraitAX5(heightMultiple: 3),
                .defaultLandscape,
            ],
        )
    }
}
