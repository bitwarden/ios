import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class VaultUnlockViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultUnlockState, VaultUnlockAction, VaultUnlockEffect>!
    var subject: VaultUnlockView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(
            state: VaultUnlockState(
                email: "user@bitwarden.com",
                profileSwitcherState: .init(
                    accounts: [],
                    activeAccountId: nil,
                    allowLockAndLogout: false,
                    isVisible: false
                ),
                unlockMethod: .password,
                webVaultHost: "bitwarden.com"
            )
        )
        let store = Store(processor: processor)

        subject = VaultUnlockView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button in the navigation bar dispatches the `.cancelPressed` action.
    @MainActor
    func test_cancelButton_tap() throws {
        processor.state.isInAppExtension = true
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .cancelPressed)
    }

    /// The secure field is visible when `isMasterPasswordRevealed` is `false`.
    @MainActor
    func test_isMasterPasswordRevealed_false() throws {
        processor.state.isMasterPasswordRevealed = false
        XCTAssertNoThrow(try subject.inspect().find(secureField: ""))
        let textField = try subject.inspect().find(textField: "")
        XCTAssertTrue(textField.isHidden())
    }

    /// The text field is visible when `isMasterPasswordRevealed` is `true`.
    @MainActor
    func test_isMasterPasswordRevealed_true() {
        processor.state.isMasterPasswordRevealed = true
        XCTAssertNoThrow(try subject.inspect().find(textField: ""))
        XCTAssertThrowsError(try subject.inspect().find(secureField: ""))
    }

    /// Tapping the options button in the navigation bar dispatches the `.morePressed` action.
    @MainActor
    func test_optionsButton_logOut_tap() throws {
        let button = try subject.inspect().find(button: Localizations.logOut)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .logOut)
    }

    /// Updating the secure field dispatches the `.masterPasswordChanged()` action.
    @MainActor
    func test_secureField_updateValue() throws {
        processor.state.isMasterPasswordRevealed = false
        let secureField = try subject.inspect().find(secureField: "")
        try secureField.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordChanged("text"))
    }

    /// Updating the text field dispatches the `.masterPasswordChanged()` action.
    @MainActor
    func test_textField_updateValue() throws {
        processor.state.isMasterPasswordRevealed = true
        let textField = try subject.inspect().find(textField: "")
        try textField.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordChanged("text"))
    }

    /// Tapping the vault unlock button dispatches the `.unlockVault` action.
    @MainActor
    func test_vaultUnlockButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.unlock)
        try await button.tap()
        waitFor(!processor.effects.isEmpty)
        XCTAssertEqual(processor.effects.last, .unlockVault)
    }

    /// Tapping the vault biometric unlock button dispatches the `.unlockVaultWithBiometrics` action.
    @MainActor
    func test_vaultUnlockWithBiometricsButton_tap() throws {
        processor.state.biometricUnlockStatus = .available(
            .faceID,
            enabled: true
        )
        var expectedString = Localizations.useFaceIDToUnlock
        var button = try subject.inspect().find(button: expectedString)

        processor.state.biometricUnlockStatus = .available(
            .touchID,
            enabled: true
        )
        expectedString = Localizations.useFingerprintToUnlock
        button = try subject.inspect().find(button: expectedString)

        processor.state.biometricUnlockStatus = .available(
            .opticID,
            enabled: true
        )
        expectedString = Localizations.useOpticIDToUnlock
        button = try subject.inspect().find(button: expectedString)

        processor.state.biometricUnlockStatus = .available(
            .unknown,
            enabled: true
        )
        expectedString = Localizations.useBiometricsToUnlock
        button = try subject.inspect().find(button: expectedString)
        try button.tap()
        waitFor(!processor.effects.isEmpty)
        XCTAssertEqual(processor.effects.last, .unlockVaultWithBiometrics)
    }

    // MARK: Snapshots

    /// Test a snapshot of the empty view.
    func test_snapshot_vaultUnlock_empty() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view with face id biometrics available.
    @MainActor
    func test_snapshot_vaultUnlock_withBiometrics_faceId() {
        processor.state.biometricUnlockStatus = .available(
            .faceID,
            enabled: true
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view with biometrics unavailable.
    @MainActor
    func test_snapshot_vaultUnlock_withBiometrics_notAvailable() {
        processor.state.biometricUnlockStatus = .notAvailable
        assertSnapshot(of: subject, as: .defaultLandscape)
    }

    /// Test a snapshot of the view with touch id biometrics available.
    @MainActor
    func test_snapshot_vaultUnlock_withBiometrics_touchId() {
        processor.state.biometricUnlockStatus = .available(
            .touchID,
            enabled: true
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view with no master password or pin but with touch id.
    @MainActor
    func test_snapshot_shouldShowPasswordOrPinFields_false_touchId() {
        processor.state.shouldShowPasswordOrPinFields = false
        processor.state.biometricUnlockStatus = .available(
            .touchID,
            enabled: true
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view with no master password or pin but with face id.
    @MainActor
    func test_snapshot_shouldShowPasswordOrPinFields_false_faceId() {
        processor.state.shouldShowPasswordOrPinFields = false
        processor.state.biometricUnlockStatus = .available(
            .faceID,
            enabled: true
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view with no master password but with pin.
    @MainActor
    func test_snapshot_shouldShowPasswordOrPinFields_true_pin() {
        processor.state.shouldShowPasswordOrPinFields = true
        processor.state.unlockMethod = .pin
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view when the password is hidden.
    @MainActor
    func test_snapshot_vaultUnlock_passwordHidden() {
        processor.state.masterPassword = "Password"
        processor.state.isMasterPasswordRevealed = false
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view when the password is revealed.
    @MainActor
    func test_snapshot_vaultUnlock_passwordRevealed() {
        processor.state.masterPassword = "Password"
        processor.state.isMasterPasswordRevealed = true
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Check the snapshot for the profiles visible
    @MainActor
    func test_snapshot_profilesVisible() {
        let account = ProfileSwitcherItem.fixture(
            email: "extra.warden@bitwarden.com",
            userInitials: "EW"
        )
        processor.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [
                account,
            ],
            activeAccountId: account.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Check the snapshot for the profiles visible
    @MainActor
    func test_snapshot_profilesVisible_max() {
        processor.state.profileSwitcherState = .maximumAccounts
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Check the snapshot for the profiles visible
    @MainActor
    func test_snapshot_profilesVisible_max_largeText() {
        processor.state.profileSwitcherState = .maximumAccounts
        assertSnapshot(of: subject, as: .defaultPortraitAX5)
    }

    /// Check the snapshot for the profiles closed
    @MainActor
    func test_snapshot_profilesClosed() {
        let account = ProfileSwitcherItem.fixture(
            email: "extra.warden@bitwarden.com",
            userInitials: "EW"
        )
        processor.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [
                account,
            ],
            activeAccountId: account.userId,
            allowLockAndLogout: true,
            isVisible: false
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
