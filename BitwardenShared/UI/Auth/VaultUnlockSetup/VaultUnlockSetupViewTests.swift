import BitwardenResources
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

        processor = MockProcessor(state: VaultUnlockSetupState(accountSetupFlow: .createAccount))

        subject = VaultUnlockSetupView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// The view displays the set up later button when in the create account flow.
    @MainActor
    func test_accountSetupFlow_createAccount() async throws {
        processor.state.accountSetupFlow = .createAccount

        XCTAssertNoThrow(try subject.inspect().find(button: Localizations.setUpLater))
    }

    /// The view hides the set up later button when in the settings flow.
    @MainActor
    func test_accountSetupFlow_settings() async {
        processor.state.accountSetupFlow = .settings

        XCTAssertThrowsError(try subject.inspect().find(button: Localizations.setUpLater))
    }

    /// Tapping the continue button dispatches the continue flow action.
    @MainActor
    func test_continue_tap() async throws {
        processor.state.biometricsStatus = .available(.faceID, enabled: true)
        let button = try subject.inspect().find(asyncButton: Localizations.continue)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .continueFlow)
    }

    /// The continue button is enabled when one or more unlock methods are enabled.
    @MainActor
    func test_continue_enabled() throws {
        var button = try subject.inspect().find(button: Localizations.continue)
        XCTAssertTrue(button.isDisabled())

        processor.state.biometricsStatus = .available(.faceID, enabled: true)
        button = try subject.inspect().find(button: Localizations.continue)
        XCTAssertFalse(button.isDisabled())

        processor.state.biometricsStatus = .available(.faceID, enabled: false)
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
        processor.state.biometricsStatus = .available(.faceID, enabled: false)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2), .defaultLandscape]
        )
    }

    /// The vault unlock setup view renders correctly when shown from settings.
    @MainActor
    func test_snapshot_vaultUnlockSetup_settings() {
        processor.state.accountSetupFlow = .settings
        processor.state.biometricsStatus = .available(.faceID, enabled: false)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)]
        )
    }

    /// The vault unlock setup view renders correctly for a device with Touch ID.
    @MainActor
    func test_snapshot_vaultUnlockSetup_touchID() {
        processor.state.biometricsStatus = .available(.touchID, enabled: false)
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
        processor.state.biometricsStatus = .available(.faceID, enabled: true)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait]
        )
    }
}
