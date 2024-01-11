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
                        biometricAuthStatus: .authorized(.touchID),
                        isApproveLoginRequestsToggleOn: true,
                        isUnlockWithBiometricsToggleOn: false,
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
                        biometricAuthStatus: .authorized(.faceID),
                        isApproveLoginRequestsToggleOn: true,
                        isUnlockWithBiometricsToggleOn: true,
                        sessionTimeoutValue: .custom
                    )
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
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
        processor.state.biometricAuthStatus = .authorized(.faceID)
        processor.state.isUnlockWithBiometricsToggleOn = false
        _ = try subject.inspect().find(
            toggleWithAccessibilityLabel: subject.store.state.biometricsToggleText
        )
    }

    /// Tapping the Lock now button dispatches the `.lockVault` effect.
    func test_lockNow_tap() throws {
        let button = try subject.inspect().find(button: Localizations.lockNow)
        let task = Task {
            try button.tap()
        }
        waitFor(processor.effects.last == .lockVault)
        task.cancel()
    }
}
