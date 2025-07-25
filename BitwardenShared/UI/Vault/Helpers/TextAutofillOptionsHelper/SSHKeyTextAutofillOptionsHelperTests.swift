import BitwardenResources
import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - SSHKeyTextAutofillOptionsHelperTests

class SSHKeyTextAutofillOptionsHelperTests: BitwardenTestCase {
    // MARK: Properties

    var subject: SSHKeyTextAutofillOptionsHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = SSHKeyTextAutofillOptionsHelper()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `getTextAutofillOptions(cipherView:)` returns all options when
    /// we have all of the values available.
    func test_getTextAutofillOptions() async {
        let cipher = CipherView.fixture(
            sshKey: .fixture(
                privateKey: "privateKey",
                publicKey: "publicKey",
                fingerprint: "fingerprint"
            ),
            type: .sshKey,
            viewPassword: true
        )
        let options = subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.privateKey), privateKey
            \(Localizations.publicKey), publicKey
            \(Localizations.fingerprint), fingerprint
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns empty when cipher doesn't have an SSH key.
    func test_getTextAutofillOptions_emptyNotSSHKey() async {
        let cipher = CipherView.fixture(
            sshKey: nil,
            type: .sshKey,
            viewPassword: true
        )
        let options = subject.getTextAutofillOptions(cipherView: cipher)
        XCTAssertTrue(options.isEmpty)
    }

    /// `getTextAutofillOptions(cipherView:)` returns options when
    /// we have all of the values available except private key empty.
    func test_getTextAutofillOptions_privateKeyEmpty() async {
        let cipher = CipherView.fixture(
            sshKey: .fixture(
                privateKey: "",
                publicKey: "publicKey",
                fingerprint: "fingerprint"
            ),
            type: .sshKey,
            viewPassword: true
        )
        let options = subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.publicKey), publicKey
            \(Localizations.fingerprint), fingerprint
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns options when
    /// we have all of the values available except public key empty.
    func test_getTextAutofillOptions_publicKeyEmpty() async {
        let cipher = CipherView.fixture(
            sshKey: .fixture(
                privateKey: "privateKey",
                publicKey: "",
                fingerprint: "fingerprint"
            ),
            type: .sshKey,
            viewPassword: true
        )
        let options = subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.privateKey), privateKey
            \(Localizations.fingerprint), fingerprint
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns options when
    /// we have all of the values available except fingerprint empty.
    func test_getTextAutofillOptions_fingeprintEmpty() async {
        let cipher = CipherView.fixture(
            sshKey: .fixture(
                privateKey: "privateKey",
                publicKey: "publicKey",
                fingerprint: ""
            ),
            type: .sshKey,
            viewPassword: true
        )
        let options = subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.privateKey), privateKey
            \(Localizations.publicKey), publicKey
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns options when
    /// we have all of the values available but cipher cannot view password.
    func test_getTextAutofillOptions_cannotViewPassword() async {
        let cipher = CipherView.fixture(
            sshKey: .fixture(
                privateKey: "privateKey",
                publicKey: "publicKey",
                fingerprint: "fingerprint"
            ),
            type: .sshKey,
            viewPassword: false
        )
        let options = subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.publicKey), publicKey
            \(Localizations.fingerprint), fingerprint
            """
        }
    }
}
