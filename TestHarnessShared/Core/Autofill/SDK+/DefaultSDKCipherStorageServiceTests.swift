import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - DefaultSDKCipherStorageServiceTests

/// Tests for `DefaultSDKCipherStorageService`.
///
class DefaultSDKCipherStorageServiceTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DefaultSDKCipherStorageService!
    var userDefaults: UserDefaults!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "DefaultSDKCipherStorageServiceTests")
        userDefaults.removePersistentDomain(forName: "DefaultSDKCipherStorageServiceTests")
        subject = DefaultSDKCipherStorageService(userDefaults: userDefaults)
    }

    override func tearDown() {
        super.tearDown()
        userDefaults.removePersistentDomain(forName: "DefaultSDKCipherStorageServiceTests")
        subject = nil
        userDefaults = nil
    }

    // MARK: Tests

    /// `loadCiphers()` returns an empty list when nothing has been saved.
    func test_loadCiphers_empty() {
        XCTAssertTrue(subject.loadCiphers().isEmpty)
    }

    /// `save(ciphers:)` followed by `loadCiphers()` returns the persisted ciphers.
    func test_save_thenLoadCiphers_returnsPersistedCiphers() {
        let cipher = Cipher(cipherView: .fixture(
            login: .fixture(fido2Credentials: [Fido2Credential(fido2CredentialView: .fixture())]),
        ))

        subject.save(ciphers: [cipher])

        XCTAssertEqual(subject.loadCiphers(), [cipher])
    }

    /// `save(ciphers:)` silently skips ciphers with no Fido2 credential, since this storage
    /// service only knows how to persist the login+Fido2 shape these scenarios create.
    func test_save_ciphersWithoutFido2Credential_areSkipped() {
        let cipher = Cipher(cipherView: .fixture(login: .fixture(fido2Credentials: nil)))

        subject.save(ciphers: [cipher])

        XCTAssertTrue(subject.loadCiphers().isEmpty)
    }

    /// Persisted ciphers remain available to a new `DefaultSDKCipherStorageService` instance
    /// backed by the same `UserDefaults`, simulating an app relaunch.
    func test_save_persistsAcrossInstances() {
        let cipher = Cipher(cipherView: .fixture(
            login: .fixture(fido2Credentials: [Fido2Credential(fido2CredentialView: .fixture())]),
        ))
        subject.save(ciphers: [cipher])

        let relaunchedSubject = DefaultSDKCipherStorageService(userDefaults: userDefaults)

        XCTAssertEqual(relaunchedSubject.loadCiphers(), [cipher])
    }
}
