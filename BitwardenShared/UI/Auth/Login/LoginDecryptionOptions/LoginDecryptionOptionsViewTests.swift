import BitwardenResources
import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class LoginDecryptionOptionsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<
        LoginDecryptionOptionsState,
        LoginDecryptionOptionsAction,
        LoginDecryptionOptionsEffect
    >!
    var subject: LoginDecryptionOptionsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(
            state: LoginDecryptionOptionsState(
                shouldShowApproveMasterPasswordButton: true,
                shouldShowApproveWithOtherDeviceButton: true,
                shouldShowContinueButton: true,
                email: "example@bitwarden.com",
                isRememberDeviceToggleOn: true,
                orgIdentifier: "Bitwarden",
                shouldShowAdminApprovalButton: true
            )
        )
        let store = Store(processor: processor)

        subject = LoginDecryptionOptionsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the approve with master password button dispatches the `.approveWithMasterPasswordPressed` action.
    @MainActor
    func test_approveMasterPasswordButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.approveWithMasterPassword)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .approveWithMasterPasswordPressed)
    }

    /// Tapping the approve with my other device button dispatches the `.approveWithOtherDevicePressed` action.
    @MainActor
    func test_approveWithOtherDeviceButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.approveWithMyOtherDevice)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .approveWithOtherDevicePressed)
    }

    /// Tapping the request admin approval  button dispatches the `.requestAdminApprovalPressed` action.
    @MainActor
    func test_approveAdminApprovalButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.requestAdminApproval)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .requestAdminApprovalPressed)
    }

    /// Tapping the continue button dispatches the `.continuePressed` action.
    @MainActor
    func test_continueButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.continue)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .continuePressed)
    }

    /// Tapping the not you button performs the `.notYouPressed` effect.
    @MainActor
    func test_notYouButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.notYou)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .notYouPressed)
    }

    /// Tapping the remember this device toggle dispatches the `.toggleRememberDevice` action.
    @MainActor
    func test_isRememberDeviceToggle_tap() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        let toggle = try subject.inspect().find(ViewType.Toggle.self)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .toggleRememberDevice(true))
    }

    // MARK: Snapshots

    /// The default view renders correctly.
    func test_snapshot_default() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
