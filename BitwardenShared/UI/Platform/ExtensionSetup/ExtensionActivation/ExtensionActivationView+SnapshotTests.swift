// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
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

    // MARK: Snapshots

    /// The autofill extension activation view renders correctly.
    func disabletest_snapshot_extensionActivationView_autoFillExtension() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The app extension activation view renders correctly.
    @MainActor
    func disabletest_snapshot_extensionActivationView_appExtension() {
        processor.state.extensionType = .appExtension
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
