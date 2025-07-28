import BitwardenResources
import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class TwoFactorAuthViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<TwoFactorAuthState, TwoFactorAuthAction, TwoFactorAuthEffect>!
    var subject: TwoFactorAuthView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: TwoFactorAuthState(displayEmail: "sh***@livefront.com"))
        let store = Store(processor: processor)

        subject = TwoFactorAuthView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping an auth method button dispatches the `.authMethodSelected()` action.
    @MainActor
    func test_authMethodButton_tap() throws {
        processor.state.availableAuthMethods = [.recoveryCode]
        let menu = try subject.inspect().find(ViewType.Menu.self, containing: Localizations.useAnotherTwoStepMethod)
        let subMenu = try menu.find(ViewType.Menu.self, containing: Localizations.recoveryCodeTitle)
        let button = try subMenu.find(button: Localizations.recoveryCodeTitle)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .authMethodSelected(.recoveryCode))
    }

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the continue button performs the `.continueTapped` effect.
    @MainActor
    func test_continueButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.continue)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .continueTapped)
    }

    /// Tapping the duo button performs the `.beginDuoAuth` effect.
    @MainActor
    func test_launchDuo_tap() async throws {
        processor.state.authMethod = .duo
        let button = try subject.inspect().find(asyncButton: Localizations.launchDuo)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .beginDuoAuth)
    }

    /// Changing the remember me toggle dispatches the `.rememberMeToggleChanged(_)` action.
    @MainActor
    func test_rememberMeToggle_changed() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        let toggle = try subject.inspect().find(ViewType.Toggle.self)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .rememberMeToggleChanged(true))
    }

    /// Tapping the resend email button performs the `.resendEmailTapped` effect.
    @MainActor
    func test_resendEmailButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.resendCode)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .resendEmailTapped)
    }

    /// Updating the value in the verification code text field dispatches the `.verificationCodeChanged(_)` action.
    @MainActor
    func test_verificationCode_updateValue() throws {
        let textField = try subject.inspect().find(textField: "")
        try textField.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .verificationCodeChanged("text"))
    }

    // MARK: Snapshots

    /// The default view renders correctly for the authenticator app method.
    @MainActor
    func test_snapshot_default_authApp() {
        processor.state.authMethod = .authenticatorApp
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The default view renders correctly for the duo method.
    @MainActor
    func test_snapshot_default_authApp_light() {
        processor.state.authMethod = .duo
        assertSnapshot(
            of: subject.navStackWrapped,
            as: .defaultPortrait
        )
    }

    /// The default view renders correctly for the duo method.
    @MainActor
    func test_snapshot_default_authApp_dark() {
        processor.state.authMethod = .duo
        assertSnapshot(
            of: subject.navStackWrapped,
            as: .defaultPortraitDark
        )
    }

    /// The default view renders correctly for the duo method.
    @MainActor
    func test_snapshot_default_authApp_largeText() {
        processor.state.authMethod = .duo
        assertSnapshot(
            of: subject.navStackWrapped,
            as: .defaultPortraitAX5
        )
    }

    /// The default view renders correctly for the email method.
    @MainActor
    func test_snapshot_default_email() {
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The default view renders correctly for the email method when filled.
    @MainActor
    func test_snapshot_default_email_filled() {
        processor.state.isRememberMeOn = true
        processor.state.verificationCode = "123456"
        processor.state.continueEnabled = true
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The default view renders correctly for the email method and device needs verification.
    @MainActor
    func test_snapshot_default_email_deviceVerificationRequired() {
        processor.state.deviceVerificationRequired = true
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The default view renders correctly for the email method when filled and device needs verification.
    @MainActor
    func test_snapshot_default_email_filled_deviceVerificationRequired() {
        processor.state.deviceVerificationRequired = true
        processor.state.verificationCode = "123456"
        processor.state.continueEnabled = true
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The default view renders correctly for the YubiKey method.
    @MainActor
    func test_snapshot_default_yubikey() {
        processor.state.authMethod = .yubiKey
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
