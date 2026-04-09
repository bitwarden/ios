// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class LoginWithDeviceViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<LoginWithDeviceState, LoginWithDeviceAction, LoginWithDeviceEffect>!
    var subject: LoginWithDeviceView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(
            state: LoginWithDeviceState(
                fingerprintPhrase: "some-weird-long-text-thing-as-a-placeholder",
            ),
        )
        let store = Store(processor: processor)

        subject = LoginWithDeviceView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The default view renders correctly.
    func disabletest_snapshot_default() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
