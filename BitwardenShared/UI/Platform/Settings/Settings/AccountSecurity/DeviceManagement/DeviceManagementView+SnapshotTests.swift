// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class DeviceManagementViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<DeviceManagementState, DeviceManagementAction, DeviceManagementEffect>!
    var subject: DeviceManagementView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: DeviceManagementState())
        let store = Store(processor: processor)

        subject = DeviceManagementView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The empty view renders correctly.
    @MainActor
    func disabletest_snapshot_empty() {
        processor.state.loadingState = .data([])
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The view with devices renders correctly, covering the current session, pending request,
    /// and trusted (not current) variants.
    @MainActor
    func disabletest_snapshot_devices() {
        processor.state.loadingState = .data([
            .fixture(id: "1", isCurrentSession: true),
            .fixture(id: "2", isTrusted: false, pendingRequest: .fixture()),
            .fixture(id: "3", isTrusted: true),
        ])
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
