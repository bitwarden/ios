import SnapshotTesting
import XCTest

@testable import BitwardenShared

class ViewSSHKeyItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SSHKeyItemState, ViewSSHKeyItemAction, Void>!
    var subject: ViewSSHKeyItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(
            state: SSHKeyItemState(
                privateKey: "privateKey",
                publicKey: "publicKey",
                keyFingerprint: "fingerprint"
            )
        )
        let store = Store(processor: processor)

        subject = ViewSSHKeyItemView(showCopyButtons: true, store: store)
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
        subject = ViewSSHKeyItemView(showCopyButtons: false, store: Store(processor: processor))

        XCTAssertThrowsError(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "SSHKeyCopyPrivateKeyButton")
        )
        XCTAssertThrowsError(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "SSHKeyCopyPublicKeyButton")
        )
        XCTAssertThrowsError(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "SSHKeyCopyFingerprintButton")
        )
    }
}
