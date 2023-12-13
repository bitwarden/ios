import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

class VaultRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var client: MockHTTPClient!
    var clientCiphers: MockClientCiphers!
    var clientCrypto: MockClientCrypto!
    var clientVault: MockClientVaultService!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: DefaultVaultRepository!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        clientCiphers = MockClientCiphers()
        clientCrypto = MockClientCrypto()
        clientVault = MockClientVaultService()
        errorReporter = MockErrorReporter()
        vaultTimeoutService = MockVaultTimeoutService()

        clientVault.clientCiphers = clientCiphers

        stateService = MockStateService()

        subject = DefaultVaultRepository(
            cipherAPIService: APIService(client: client),
            clientCrypto: clientCrypto,
            clientVault: clientVault,
            errorReporter: errorReporter,
            stateService: stateService,
            syncAPIService: APIService(client: client),
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        clientCiphers = nil
        clientCrypto = nil
        clientVault = nil
        errorReporter = nil
        stateService = nil
        subject = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// Tests `vaultTimeoutService.lock()` publishes the correct value for whether or not the vault was locked.
    func test_vault_isLocked_shouldClear() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)

        try await subject.fetchSync()
        XCTAssertNotNil(subject.syncResponseSubject.value)

        vaultTimeoutService.shouldClear = true
        await subject.vaultTimeoutService.lockVault(userId: "")
        waitFor(subject.syncResponseSubject.value == nil)
        XCTAssertNil(subject.syncResponseSubject.value)
    }

    /// Tests `vaultTimeoutService.lock()` publishes the correct value for whether or not the vault was locked.
    func test_vault_isLocked_shouldNotClear() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)

        try await subject.fetchSync()
        XCTAssertNotNil(subject.syncResponseSubject.value)

        vaultTimeoutService.shouldClear = false
        await subject.vaultTimeoutService.lockVault(userId: "")
        waitFor(subject.syncResponseSubject.value != nil)
        XCTAssertNotNil(subject.syncResponseSubject.value)
    }

    /// `addCipher()` makes the add cipher API request and updates the vault.
    func test_addCipher() async throws {
        client.results = [
            .httpSuccess(testData: .cipherResponse),
            .httpSuccess(testData: .syncWithCipher),
        ]

        let cipher = CipherView.fixture()
        try await subject.addCipher(cipher)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers")
        XCTAssertEqual(client.requests[1].url.absoluteString, "https://example.com/api/sync")

        XCTAssertEqual(clientCiphers.encryptedCiphers, [cipher])
    }

    /// `addCipher()` throws an error if encrypting the cipher fails.
    func test_addCipher_encryptError() async {
        struct EncryptError: Error, Equatable {}

        clientCiphers.encryptError = EncryptError()

        await assertAsyncThrows(error: EncryptError()) {
            try await subject.addCipher(.fixture())
        }
    }

    /// `updateCipher()` throws on encryption errors.
    func test_updateCipher_encryptError() async throws {
        struct EncryptError: Error, Equatable {}

        clientCiphers.encryptError = EncryptError()

        await assertAsyncThrows(error: EncryptError()) {
            try await subject.updateCipher(.fixture(id: "1"))
        }
    }

    /// `updateCipher()` throws on id errors.
    func test_updateCipher_idError_nil() async throws {
        await assertAsyncThrows(error: CipherAPIServiceError.updateMissingId) {
            try await subject.updateCipher(.fixture(id: nil))
        }
    }

    /// `updateCipher()` throws on id errors.
    func test_updateCipher_idError_empty() async throws {
        await assertAsyncThrows(error: CipherAPIServiceError.updateMissingId) {
            try await subject.updateCipher(.fixture(id: ""))
        }
    }

    /// `updateCipher()` makes the update cipher API request and updates the vault.
    func test_updateCipher() async throws {
        client.results = [
            .httpSuccess(testData: .cipherResponse),
            .httpSuccess(testData: .syncWithCipher),
        ]

        let cipher = CipherView.fixture(id: "123")
        try await subject.updateCipher(cipher)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/123")
        XCTAssertEqual(client.requests[1].url.absoluteString, "https://example.com/api/sync")

        XCTAssertEqual(clientCiphers.encryptedCiphers, [cipher])
    }

    /// `fetchSync()` performs the sync API request.
    func test_fetchSync() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)

        try await subject.fetchSync()

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].method, .get)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/sync")
    }

    /// `fetchSync()` throws an error if the request fails.
    func test_fetchSync_error() async throws {
        client.result = .httpFailure()

        await assertAsyncThrows {
            try await subject.fetchSync()
        }
    }

    /// `fetchSync()` initializes the SDK for decrypting organization ciphers.
    func test_fetchSync_initializeOrgCrypto() async throws {
        client.result = .httpSuccess(testData: .syncWithProfileOrganizations)

        try await subject.fetchSync()

        XCTAssertEqual(
            clientCrypto.initializeOrgCryptoRequest,
            InitOrgCryptoRequest(organizationKeys: [
                "ORG_2": "ORG_2_KEY",
                "ORG_1": "ORG_1_KEY",
            ])
        )
    }

    /// `fetchSync()` logs an error to the error reporter if initializing organization crypto fails.
    func test_fetchSync_initializeOrgCrypto_error() async throws {
        struct InitializeOrgCryptoError: Error {}

        client.result = .httpSuccess(testData: .syncWithProfileOrganizations)
        clientCrypto.initializeOrgCryptoResult = .failure(InitializeOrgCryptoError())

        try await subject.fetchSync()

        XCTAssertTrue(errorReporter.errors.last is InitializeOrgCryptoError)
    }

    /// `fetchSync()` initializes the SDK for decrypting organization ciphers with an empty
    /// dictionary if the user isn't a part of any organizations.
    func test_fetchSync_initializesOrgCrypto_noOrganizations() async throws {
        client.result = .httpSuccess(testData: .syncWithProfile)

        try await subject.fetchSync()

        XCTAssertEqual(
            clientCrypto.initializeOrgCryptoRequest,
            InitOrgCryptoRequest(organizationKeys: [:])
        )
    }

    /// `cipherDetailsPublisher(id:)` returns a publisher for the details of a cipher in the vault.
    func test_cipherDetailsPublisher() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)

        var iterator = subject.cipherDetailsPublisher(id: "fdabf83f-f1c0-4703-894d-4c0fd6741a9a").makeAsyncIterator()

        Task {
            try await subject.fetchSync()
        }

        let cipherDetails = await iterator.next()

        XCTAssertEqual(cipherDetails?.name, "Apple")
    }

    /// `remove(userId:)` Removes an account id from the vault timeout service.
    func test_removeAccountId_success_unlocked() async {
        let account = Account.fixtureAccountLogin()
        vaultTimeoutService.timeoutStore = [
            account.profile.userId: false,
        ]
        await subject.remove(userId: account.profile.userId)
        XCTAssertEqual([:], vaultTimeoutService.timeoutStore)
    }

    /// `remove(userId:)` Removes an account id from the vault timeout service.
    func test_removeAccountId_success_locked() async {
        let account = Account.fixtureAccountLogin()
        vaultTimeoutService.timeoutStore = [
            account.profile.userId: true,
        ]
        await subject.remove(userId: account.profile.userId)
        XCTAssertEqual([:], vaultTimeoutService.timeoutStore)
    }

    /// `remove(userId:)` Throws no error when no account is found.
    func test_removeAccountId_failure() async {
        let account = Account.fixtureAccountLogin()
        vaultTimeoutService.timeoutStore = [
            account.profile.userId: false,
        ]
        await subject.remove(userId: "123")
        XCTAssertEqual(
            [
                account.profile.userId: false,
            ],
            vaultTimeoutService.timeoutStore
        )
    }

    /// `vaultListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the vault.
    func test_vaultListPublisher() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)

        var iterator = subject.vaultListPublisher().makeAsyncIterator()

        Task {
            try await subject.fetchSync()
        }

        let sections = await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListSections(XCTUnwrap(sections)), as: .lines) {
            """
            Section: Favorites
              - Cipher: Apple
            Section: Types
              - Group: Login (2)
              - Group: Card (1)
              - Group: Identity (1)
              - Group: Secure note (1)
            Section: Folders
              - Group: Social (1)
            Section: No Folder
              - Cipher: Apple
              - Cipher: Bitwarden User
              - Cipher: Top Secret Note
              - Cipher: Visa
            Section: Trash
              - Group: Trash (1)
            """
        }
    }

    /// `vaultListPublisher()` returns a publisher which publishes an empty array if the user's
    /// vault contains no ciphers.
    func test_vaultListPublisher_empty() async throws {
        client.result = .httpSuccess(testData: .syncWithProfile)

        var iterator = subject.vaultListPublisher().makeAsyncIterator()

        Task {
            try await subject.fetchSync()
        }

        let sections = await iterator.next()

        try XCTAssertTrue(XCTUnwrap(sections).isEmpty)
    }

    /// `vaultListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the vault for a vault that contains collections.
    func test_vaultListPublisher_withCollections() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphersCollections)

        var iterator = subject.vaultListPublisher().makeAsyncIterator()

        Task {
            try await subject.fetchSync()
        }

        let sections = await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListSections(XCTUnwrap(sections)), as: .lines) {
            """
            Section: Favorites
              - Cipher: Apple
            Section: Types
              - Group: Login (3)
              - Group: Card (1)
              - Group: Identity (1)
              - Group: Secure note (1)
            Section: Folders
              - Group: Social (1)
            Section: No Folder
              - Cipher: Apple
              - Cipher: Bitwarden User
              - Cipher: Figma
              - Cipher: Top Secret Note
              - Cipher: Visa
            Section: Collections
              - Group: Design (1)
              - Group: Engineering (1)
            Section: Trash
              - Group: Trash (1)
            """
        }
    }

    /// `vaultListPublisher(group:)` returns a publisher for a group of login items within the vault list.
    func test_vaultListPublisher_forGroup_login() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)

        var iterator = subject.vaultListPublisher(group: .login).makeAsyncIterator()

        Task {
            try await subject.fetchSync()
        }

        let items = await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListItems(XCTUnwrap(items)), as: .lines) {
            """
            - Cipher: Apple
            - Cipher: Facebook
            """
        }
    }

    /// `vaultListPublisher(group:)` returns a publisher for a group of items in a collection within
    /// the vault list.
    func test_vaultListPublisher_forGroup_collection() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphersCollections)

        var iterator = subject.vaultListPublisher(
            group: .collection(id: "f96de98e-618a-4886-b396-66b92a385325", name: "Engineering")
        ).makeAsyncIterator()

        Task {
            try await subject.fetchSync()
        }

        let items = await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListItems(XCTUnwrap(items)), as: .lines) {
            """
            - Cipher: Apple
            """
        }
    }

    // MARK: Private

    /// Returns a string containing a description of the vault list items.
    func dumpVaultListItems(_ items: [VaultListItem], indent: String = "") -> String {
        guard !items.isEmpty else { return indent + "(empty)" }
        return items.reduce(into: "") { result, item in
            switch item.itemType {
            case let .cipher(cipher):
                result.append(indent + "- Cipher: \(cipher.name)")
            case let .group(group, count):
                result.append(indent + "- Group: \(group.name) (\(count))")
            }
            if item != items.last {
                result.append("\n")
            }
        }
    }

    /// Returns a string containing a description of the vault list sections.
    func dumpVaultListSections(_ sections: [VaultListSection]) -> String {
        sections.reduce(into: "") { result, section in
            result.append("Section: \(section.name)\n")
            result.append(dumpVaultListItems(section.items, indent: "  "))
            if section != sections.last {
                result.append("\n")
            }
        }
    }
}
