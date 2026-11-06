import AuthenticationServices
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@available(iOS 26.2, *)
class GeneratePasswordExtensionDelegateTests: BitwardenTestCase {
    // MARK: Properties

    var extensionDelegate: MockCredentialProviderExtensionDelegate!
    var subject: GeneratePasswordExtensionDelegate!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        extensionDelegate = MockCredentialProviderExtensionDelegate()
        subject = GeneratePasswordExtensionDelegate(extensionDelegate: extensionDelegate)
    }

    override func tearDown() {
        super.tearDown()

        extensionDelegate = nil
        subject = nil
    }

    // MARK: Tests

    /// `didCancelGenerator()` forwards cancellation to the extension delegate.
    @MainActor
    func test_didCancelGenerator_callsDidCancel() {
        subject.didCancelGenerator()

        XCTAssertTrue(extensionDelegate.didCancelCalled)
    }

    /// `didCompleteGenerator(for:with:)` maps a passphrase type to `.passphrase`
    /// regardless of the password value's characters.
    @MainActor
    func test_didCompleteGenerator_passphrase_mapsToPassphrase() {
        subject.didCompleteGenerator(for: .passphrase, with: "correct-horse-battery-staple")

        XCTAssertEqual(
            extensionDelegate.completeGeneratePasswordRequestKind as? ASGeneratedPassword.Kind,
            .passphrase,
        )
        XCTAssertEqual(extensionDelegate.completeGeneratePasswordRequestPassword, "correct-horse-battery-staple")
    }

    /// `didCompleteGenerator(for:with:)` maps a passphrase type containing special characters
    /// to `.passphrase`, not `.strong` — generator type takes precedence over character inspection.
    @MainActor
    func test_didCompleteGenerator_passphraseWithSpecialChars_mapsToPassphrase() {
        subject.didCompleteGenerator(for: .passphrase, with: "correct-horse!")

        XCTAssertEqual(
            extensionDelegate.completeGeneratePasswordRequestKind as? ASGeneratedPassword.Kind,
            .passphrase,
        )
    }

    /// `didCompleteGenerator(for:with:)` maps a password containing special characters to `.strong`.
    @MainActor
    func test_didCompleteGenerator_passwordWithSpecialChars_mapsToStrong() {
        subject.didCompleteGenerator(for: .password, with: "P@ssw0rd!")

        XCTAssertEqual(
            extensionDelegate.completeGeneratePasswordRequestKind as? ASGeneratedPassword.Kind,
            .strong,
        )
        XCTAssertEqual(extensionDelegate.completeGeneratePasswordRequestPassword, "P@ssw0rd!")
    }

    /// `didCompleteGenerator(for:with:)` maps an alphanumeric password to `.alphanumeric`.
    @MainActor
    func test_didCompleteGenerator_alphanumericPassword_mapsToAlphanumeric() {
        subject.didCompleteGenerator(for: .password, with: "Abc123xyz")

        XCTAssertEqual(
            extensionDelegate.completeGeneratePasswordRequestKind as? ASGeneratedPassword.Kind,
            .alphanumeric,
        )
        XCTAssertEqual(extensionDelegate.completeGeneratePasswordRequestPassword, "Abc123xyz")
    }
}
