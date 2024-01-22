import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AccountSecurityViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AccountSecurityState, AccountSecurityAction, AccountSecurityEffect>!
    var subject: AccountSecurityView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AccountSecurityState())
        let store = Store(processor: processor)

        subject = AccountSecurityView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The view renders correctly when biometrics are available.
    func test_snapshot_biometricsDisabled_touchID() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        biometricUnlockStatus: .available(
                            .touchID,
                            enabled: false,
                            hasValidIntegrity: true
                        ),
                        isApproveLoginRequestsToggleOn: true,
                        sessionTimeoutValue: .custom
                    )
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when biometrics are available.
    func test_snapshot_biometricsEnabled_faceID() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        biometricUnlockStatus: .available(
                            .faceID,
                            enabled: true,
                            hasValidIntegrity: true
                        ),
                        isApproveLoginRequestsToggleOn: true,
                        sessionTimeoutValue: .custom
                    )
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when biometrics are available.
    func test_snapshot_biometricsEnabled_faceID_nonValidIntegrity_dark() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        biometricUnlockStatus: .available(
                            .faceID,
                            enabled: true,
                            hasValidIntegrity: false
                        ),
                        isApproveLoginRequestsToggleOn: true,
                        sessionTimeoutValue: .custom
                    )
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortraitDark)
    }

    /// The view renders correctly when showing the custom session timeout field.
    func test_snapshot_customSessionTimeoutField() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        isApproveLoginRequestsToggleOn: true,
                        sessionTimeoutValue: .custom
                    )
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly.
    func test_view_render() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    // MARK: Button taps

    /// Tapping the Account fingerprint phrase button dispatches the `.accountFingerprintPhrasePressed` effect.
    func test_accountFingerprintPhrase_tap() throws {
        let button = try subject.inspect().find(button: Localizations.accountFingerprintPhrase)
        let task = Task {
            try button.tap()
        }
        waitFor(processor.effects.last == .accountFingerprintPhrasePressed)
        task.cancel()
    }

    /// The view displays a biometrics toggle.
    func test_biometricsToggle() throws {
        processor.state.biometricUnlockStatus = .available(.faceID, enabled: false, hasValidIntegrity: false)
        _ = try subject.inspect().find(
            toggleWithAccessibilityLabel: Localizations.unlockWith(Localizations.faceID)
        )
        processor.state.biometricUnlockStatus = .available(.touchID, enabled: true, hasValidIntegrity: true)
        _ = try subject.inspect().find(
            toggleWithAccessibilityLabel: Localizations.unlockWith(Localizations.touchID)
        )
    }

    /// The view hides the biometrics toggle when appropriate.
    func test_biometricsToggle_hidden() throws {
        processor.state.biometricUnlockStatus = .notAvailable
        XCTAssertNil(
            try? subject.inspect().find(
                toggleWithAccessibilityLabel: Localizations.unlockWith(Localizations.faceID)
            )
        )
    }

    /// Tapping the Lock now button dispatches the `.lockVault` effect.
    func test_lockNow_tap() throws {
        let button = try subject.inspect().find(button: Localizations.lockNow)
        let task = Task {
            try button.tap()
        }
        waitFor(processor.effects.last == .lockVault(userInitiated: true))
        task.cancel()
    }
}
