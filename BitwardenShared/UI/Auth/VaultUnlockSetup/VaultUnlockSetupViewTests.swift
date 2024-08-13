import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class VaultUnlockSetupViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultUnlockSetupState, VaultUnlockSetupAction, VaultUnlockSetupEffect>!
    var subject: VaultUnlockSetupView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: VaultUnlockSetupState())

        subject = VaultUnlockSetupView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the continue button dispatches the continue flow action.
    @MainActor
    func test_continue_tap() throws {
        processor.state.isBiometricUnlockOn = true
        let button = try subject.inspect().find(button: Localizations.continue)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .continueFlow)
    }

    /// The continue button is enabled when one or more unlock methods are enabled.
    @MainActor
    func test_continue_enabled() throws {
        var button = try subject.inspect().find(button: Localizations.continue)
        XCTAssertTrue(button.isDisabled())

        processor.state.isBiometricUnlockOn = true
        button = try subject.inspect().find(button: Localizations.continue)
        XCTAssertFalse(button.isDisabled())

        processor.state.isBiometricUnlockOn = false
        processor.state.isPinUnlockOn = true
        button = try subject.inspect().find(button: Localizations.continue)
        XCTAssertFalse(button.isDisabled())
    }

    /// Tapping the set up later button dispatches the set up later action.
    @MainActor
    func test_setUpLater_tap() throws {
        let button = try subject.inspect().find(button: Localizations.setUpLater)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .setUpLater)
    }

    // MARK: Snapshots

    /// The vault unlock setup view renders correctly.
    @MainActor
    func test_snapshot_vaultUnlockSetup() {
        processor.state.biometricsStatus = .available(.faceID, enabled: false, hasValidIntegrity: false)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2), .defaultLandscape]
        )
    }

    /// The vault unlock setup view renders correctly for a device with Touch ID.
    @MainActor
    func test_snapshot_vaultUnlockSetup_touchID() {
        processor.state.biometricsStatus = .available(.touchID, enabled: false, hasValidIntegrity: false)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait]
        )
    }

    /// The vault unlock setup view renders correctly for a device without biometrics.
    @MainActor
    func test_snapshot_vaultUnlockSetup_noBiometrics() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait]
        )
    }

    /// The vault unlock setup view renders correctly with an unlock method enabled.
    @MainActor
    func test_snapshot_vaultUnlockSetup_unlockMethodEnabled() {
        processor.state.biometricsStatus = .available(.faceID, enabled: false, hasValidIntegrity: false)
        processor.state.isBiometricUnlockOn = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait]
        )
    }
}
