// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

class ViewSSHKeyItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SSHKeyItemState, ViewSSHKeyItemAction, Void>!
    var subject: ViewSSHKeyItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        initSubject(canViewPrivateKey: true, showCopyButtons: true)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// The processor gets the action when the private key visibility toggle is pressed.
    @MainActor
    func test_privateKeyVisibilityToggle_pressed() throws {
        let button = try subject.inspect().find(viewWithAccessibilityIdentifier: "PrivateKeyVisibilityToggle").button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .privateKeyVisibilityPressed)
    }

    /// The processor gets the action when copying the private key.
    @MainActor
    func test_copyPrivateKeyButton_pressed() throws {
        let button = try subject.inspect().find(viewWithAccessibilityIdentifier: "SSHKeyCopyPrivateKeyButton").button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "privateKey", field: .sshPrivateKey))
    }

    /// The PrivateKeyVisibilityToggle is not found when can't view private key.
    @MainActor
    func test_privateKeyVisibilityToggle_notFoundIfCantViewPrivateKey() throws {
        initSubject(canViewPrivateKey: false, showCopyButtons: true)
        XCTAssertThrowsError(
            try subject.inspect().find(
                viewWithAccessibilityIdentifier: "PrivateKeyVisibilityToggle",
            ).button(),
        )
    }

    /// The SSHKeyCopyPrivateKeyButton is not found when can't view private key.
    @MainActor
    func test_copyPrivateKeyButton_notFoundIfCantViewPrivateKey() throws {
        initSubject(canViewPrivateKey: false, showCopyButtons: true)
        XCTAssertThrowsError(
            try subject.inspect().find(
                viewWithAccessibilityIdentifier: "SSHKeyCopyPrivateKeyButton",
            ).button(),
        )
    }

    /// The processor gets the action when copying the public key.
    @MainActor
    func test_copyPublicKeyButton_pressed() throws {
        let button = try subject.inspect().find(viewWithAccessibilityIdentifier: "SSHKeyCopyPublicKeyButton").button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "publicKey", field: .sshPublicKey))
    }

    /// The processor gets the action when copying the key fingerprint.
    @MainActor
    func test_copyKeyFingerprintButton_pressed() throws {
        let button = try subject.inspect().find(viewWithAccessibilityIdentifier: "SSHKeyCopyFingerprintButton").button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "fingerprint", field: .sshKeyFingerprint))
    }

    /// Copy buttons are not shown when `showCopyButtons` is `false`.
    @MainActor
    func test_copy_notShown() throws {
        initSubject(canViewPrivateKey: true, showCopyButtons: false)

        XCTAssertThrowsError(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "SSHKeyCopyPrivateKeyButton"),
        )
        XCTAssertThrowsError(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "SSHKeyCopyPublicKeyButton"),
        )
        XCTAssertThrowsError(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "SSHKeyCopyFingerprintButton"),
        )
    }

    // MARK: Private

    /// Inits the subject with customization
    /// - Parameters:
    ///   - canViewPrivateKey: Whether the private key can be viewed.
    ///   - showCopyButtons: Whether to show copy buttons.
    @MainActor
    func initSubject(canViewPrivateKey: Bool, showCopyButtons: Bool) {
        processor = MockProcessor(
            state: SSHKeyItemState(
                canViewPrivateKey: canViewPrivateKey,
                privateKey: "privateKey",
                publicKey: "publicKey",
                keyFingerprint: "fingerprint",
            ),
        )
        let store = Store(processor: processor)

        subject = ViewSSHKeyItemView(showCopyButtons: showCopyButtons, store: store)
    }
}
