import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class VaultRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var client: MockHTTPClient!
    var clientAuth: MockClientAuth!
    var clientCiphers: MockClientCiphers!
    var clientCrypto: MockClientCrypto!
    var clientVault: MockClientVaultService!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: DefaultVaultRepository!
    var syncService: MockSyncService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        clientAuth = MockClientAuth()
        clientCiphers = MockClientCiphers()
        clientCrypto = MockClientCrypto()
        clientVault = MockClientVaultService()
        errorReporter = MockErrorReporter()
        syncService = MockSyncService()
        vaultTimeoutService = MockVaultTimeoutService()

        clientVault.clientCiphers = clientCiphers

        stateService = MockStateService()

        subject = DefaultVaultRepository(
            cipherAPIService: APIService(client: client),
            clientAuth: clientAuth,
            clientCrypto: clientCrypto,
            clientVault: clientVault,
            errorReporter: errorReporter,
            stateService: stateService,
            syncService: syncService,
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        clientAuth = nil
        clientCiphers = nil
        clientCrypto = nil
        clientVault = nil
        errorReporter = nil
        stateService = nil
        subject = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `addCipher()` makes the add cipher API request and updates the vault.
    func test_addCipher() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        client.results = [
            .httpSuccess(testData: .cipherResponse),
            .httpSuccess(testData: .syncWithCipher),
        ]

        let cipher = CipherView.fixture()
        try await subject.addCipher(cipher)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers")

        XCTAssertEqual(clientCiphers.encryptedCiphers, [cipher])
        XCTAssertTrue(syncService.didFetchSync)
    }

    /// `addCipher()` throws an error if encrypting the cipher fails.
    func test_addCipher_encryptError() async {
        struct EncryptError: Error, Equatable {}

        clientCiphers.encryptError = EncryptError()

        await assertAsyncThrows(error: EncryptError()) {
            try await subject.addCipher(.fixture())
        }
    }

    /// `fetchSync(isManualRefresh:)` only syncs when expected.
    func test_fetchSync() async throws {
        stateService.activeAccount = .fixture()

        // If it's not a manual refresh, it should sync.
        try await subject.fetchSync(isManualRefresh: false)
        XCTAssertTrue(syncService.didFetchSync)

        // If it's a manual refresh and the user has allowed sync on refresh,
        // it should sync.
        syncService.didFetchSync = false
        stateService.allowSyncOnRefresh["1"] = true
        try await subject.fetchSync(isManualRefresh: true)
        XCTAssertTrue(syncService.didFetchSync)

        // If it's a manual refresh and the user has not allowed sync on refresh,
        // it should not sync.
        syncService.didFetchSync = false
        stateService.allowSyncOnRefresh["1"] = false
        try await subject.fetchSync(isManualRefresh: true)
        XCTAssertFalse(syncService.didFetchSync)
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
        stateService.activeAccount = .fixtureAccountLogin()
        client.result = .httpSuccess(testData: .cipherResponse)

        let cipher = CipherView.fixture(id: "123")
        try await subject.updateCipher(cipher)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/123")

        XCTAssertEqual(clientCiphers.encryptedCiphers, [cipher])
        XCTAssertTrue(syncService.didFetchSync)
    }

    /// `cipherDetailsPublisher(id:)` returns a publisher for the details of a cipher in the vault.
    func test_cipherDetailsPublisher() async throws {
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphers.data
        ))

        var iterator = subject.cipherDetailsPublisher(id: "fdabf83f-f1c0-4703-894d-4c0fd6741a9a").makeAsyncIterator()
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

    /// `validatePassword(_:)` returns `true` if the master password matches the stored password hash.
    func test_validatePassword() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.masterPasswordHashes["1"] = "wxyz4321"
        clientAuth.validatePasswordResult = true

        let isValid = try await subject.validatePassword("test1234")

        XCTAssertTrue(isValid)
        XCTAssertEqual(clientAuth.validatePasswordPassword, "test1234")
        XCTAssertEqual(clientAuth.validatePasswordPasswordHash, "wxyz4321")
    }

    /// `validatePassword(_:)` returns `false` if there's no stored password hash.
    func test_validatePassword_noPasswordHash() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let isValid = try await subject.validatePassword("not the password")

        XCTAssertFalse(isValid)
    }

    /// `validatePassword(_:)` returns `false` if the master password doesn't match the stored password hash.
    func test_validatePassword_notValid() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.masterPasswordHashes["1"] = "wxyz4321"
        clientAuth.validatePasswordResult = false

        let isValid = try await subject.validatePassword("not the password")

        XCTAssertFalse(isValid)
    }

    /// `vaultListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the vault.
    func test_vaultListPublisher() async throws {
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphers.data
        ))

        var iterator = subject.vaultListPublisher().makeAsyncIterator()
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
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithProfile.data
        ))

        var iterator = subject.vaultListPublisher().makeAsyncIterator()
        let sections = await iterator.next()

        try XCTAssertTrue(XCTUnwrap(sections).isEmpty)
    }

    /// `vaultListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the vault for a vault that contains collections.
    func test_vaultListPublisher_withCollections() async throws {
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphersCollections.data
        ))

        var iterator = subject.vaultListPublisher().makeAsyncIterator()
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
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphers.data
        ))

        var iterator = subject.vaultListPublisher(group: .login).makeAsyncIterator()
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
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphersCollections.data
        ))

        var iterator = subject.vaultListPublisher(
            group: .collection(id: "f96de98e-618a-4886-b396-66b92a385325", name: "Engineering")
        ).makeAsyncIterator()
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
