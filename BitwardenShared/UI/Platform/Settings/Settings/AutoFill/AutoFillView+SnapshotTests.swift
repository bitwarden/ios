// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
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

    // MARK: Snapshots

    /// The view renders correctly with the autofill action card is displayed.
    @MainActor
    func disabletest_snapshot_actionCardAutofill() async {
        processor.state.badgeState = .fixture(autofillSetupProgress: .setUpLater)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The view renders correctly with the autofill regular expression selected
    @MainActor
    func disabletest_snapshot_regularExpressionUriMatchType() async {
        processor.state.defaultUriMatchType = UriMatchType.regularExpression
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The view renders correctly with the autofill starts with selected
    @MainActor
    func disabletest_snapshot_startsWithUriMatchType() async {
        processor.state.defaultUriMatchType = UriMatchType.startsWith
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The view renders correctly.
    @MainActor
    func disabletest_view_render() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
