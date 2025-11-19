// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
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

    // MARK: Snapshots

    /// The default view renders correctly for the authenticator app method.
    @MainActor
    func disabletest_snapshot_default_authApp() {
        processor.state.authMethod = .authenticatorApp
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The default view renders correctly for the duo method.
    @MainActor
    func disabletest_snapshot_default_authApp_light() {
        processor.state.authMethod = .duo
        assertSnapshot(
            of: subject.navStackWrapped,
            as: .defaultPortrait,
        )
    }

    /// The default view renders correctly for the duo method.
    @MainActor
    func disabletest_snapshot_default_authApp_dark() {
        processor.state.authMethod = .duo
        assertSnapshot(
            of: subject.navStackWrapped,
            as: .defaultPortraitDark,
        )
    }

    /// The default view renders correctly for the duo method.
    @MainActor
    func disabletest_snapshot_default_authApp_largeText() {
        processor.state.authMethod = .duo
        assertSnapshot(
            of: subject.navStackWrapped,
            as: .defaultPortraitAX5,
        )
    }

    /// The default view renders correctly for the email method.
    @MainActor
    func disabletest_snapshot_default_email() {
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The default view renders correctly for the email method when filled.
    @MainActor
    func disabletest_snapshot_default_email_filled() {
        processor.state.isRememberMeOn = true
        processor.state.verificationCode = "123456"
        processor.state.continueEnabled = true
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The default view renders correctly for the email method and device needs verification.
    @MainActor
    func disabletest_snapshot_default_email_deviceVerificationRequired() {
        processor.state.deviceVerificationRequired = true
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The default view renders correctly for the email method when filled and device needs verification.
    @MainActor
    func disabletest_snapshot_default_email_filled_deviceVerificationRequired() {
        processor.state.deviceVerificationRequired = true
        processor.state.verificationCode = "123456"
        processor.state.continueEnabled = true
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The default view renders correctly for the YubiKey method.
    @MainActor
    func disabletest_snapshot_default_yubikey() {
        processor.state.authMethod = .yubiKey
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
