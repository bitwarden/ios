// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - UpdateMasterPasswordViewTests

class UpdateMasterPasswordViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<UpdateMasterPasswordState, UpdateMasterPasswordAction, UpdateMasterPasswordEffect>!
    var subject: UpdateMasterPasswordView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let state = UpdateMasterPasswordState(
            currentMasterPassword: "current master password",
            masterPassword: "new master password",
            masterPasswordHint: "new master password hint",
            masterPasswordPolicy: .init(
                minComplexity: 0,
                minLength: 20,
                requireUpper: true,
                requireLower: false,
                requireNumbers: false,
                requireSpecial: false,
                enforceOnLogin: true,
            ),
            masterPasswordRetype: "new master password",
        )
        processor = MockProcessor(state: state)
        subject = UpdateMasterPasswordView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// A snapshot of the view with all filled values fields.
    @MainActor
    func disabletest_snapshot_resetPassword_withFilled_default() {
        processor.state.forcePasswordResetReason = .adminForcePasswordReset
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.portrait(heightMultiple: 1.25)],
        )
    }

    /// A snapshot of the view with all filled values fields in a dark mode.
    @MainActor
    func disabletest_snapshot_resetPassword_withFilled_dark() {
        processor.state.forcePasswordResetReason = .adminForcePasswordReset
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.portraitDark(heightMultiple: 1.25)],
        )
    }

    /// A snapshot of the view with all filled values fields in a large text.
    @MainActor
    func disabletest_snapshot_resetPassword_withFilled_large() {
        processor.state.forcePasswordResetReason = .adminForcePasswordReset
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.tallPortraitAX5(heightMultiple: 6)],
        )
    }

    /// A snapshot of the view with all filled values fields.
    @MainActor
    func disabletest_snapshot_weakPassword_withFilled_default() {
        processor.state.forcePasswordResetReason = .weakMasterPasswordOnLogin
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.portrait(heightMultiple: 1.25)],
        )
    }

    /// A snapshot of the view with all filled values fields in a dark mode.
    @MainActor
    func disabletest_snapshot_weakPassword_withFilled_dark() {
        processor.state.forcePasswordResetReason = .weakMasterPasswordOnLogin
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.portraitDark(heightMultiple: 1.25)],
        )
    }

    /// A snapshot of the view with all filled values fields in a large text.
    @MainActor
    func disabletest_snapshot_weakPassword_withFilled_large() {
        processor.state.forcePasswordResetReason = .weakMasterPasswordOnLogin
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.tallPortraitAX5(heightMultiple: 6)],
        )
    }
}
