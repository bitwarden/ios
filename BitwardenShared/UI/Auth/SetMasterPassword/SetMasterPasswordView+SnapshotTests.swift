// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class SetMasterPasswordViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SetMasterPasswordState, SetMasterPasswordAction, SetMasterPasswordEffect>!
    var subject: SetMasterPasswordView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SetMasterPasswordState(organizationIdentifier: "ORG_ID"))
        subject = SetMasterPasswordView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// A snapshot of the view with all filled values fields.
    @MainActor
    func disabletest_snapshot_setPassword_filled() {
        processor.state.masterPassword = "password123"
        processor.state.masterPasswordRetype = "password123"
        processor.state.masterPasswordHint = "hint hint"
        processor.state.resetPasswordAutoEnroll = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                "portrait": .portrait(),
                "portraitDark": .portraitDark(),
                "tallPortraitAX5": .tallPortraitAX5(),
            ],
        )
    }

    /// A snapshot of the view for privilege elevation.
    @MainActor
    func disabletest_snapshot_setPassword_privilege_elevation() {
        processor.state.isPrivilegeElevation = true
        processor.state.masterPassword = "password123"
        processor.state.masterPasswordRetype = "password123"
        processor.state.masterPasswordHint = "hint hint"
        processor.state.resetPasswordAutoEnroll = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                "portrait": .portrait(),
                "portraitDark": .portraitDark(),
                "tallPortraitAX5": .tallPortraitAX5(),
            ],
        )
    }
}
