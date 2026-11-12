// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AuthenticatorShared

// MARK: - VaultUnlockViewTests

class VaultUnlockViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultUnlockState, VaultUnlockAction, VaultUnlockEffect>!
    var subject: VaultUnlockView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let state = VaultUnlockState()
        processor = MockProcessor(state: state)
        subject = VaultUnlockView(
            store: Store(processor: processor),
        )
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Test a snapshot of the view when biometric unlock is available but not enabled.
    @MainActor
    func test_snapshot_biometricsNotEnabled() {
        processor.state.biometricUnlockStatus = .available(.faceID, enabled: false)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
                .defaultLandscape,
                .defaultLandscapeAX5,
            ],
        )
    }

    /// Test a snapshot of the view with the Face ID unlock button.
    @MainActor
    func test_snapshot_faceID() {
        processor.state.biometricUnlockStatus = .available(.faceID, enabled: true)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
                .defaultLandscape,
                .defaultLandscapeAX5,
            ],
        )
    }

    /// Test a snapshot of the view with the Touch ID unlock button.
    @MainActor
    func test_snapshot_touchID() {
        processor.state.biometricUnlockStatus = .available(.touchID, enabled: true)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
                .defaultLandscape,
                .defaultLandscapeAX5,
            ],
        )
    }
}
