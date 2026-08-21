import BitwardenKit
import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

struct CustomHeadersServiceTests {
    // MARK: Properties

    var environmentService: MockEnvironmentService
    var errorReporter: MockErrorReporter
    var keychainRepository: MockKeychainRepository
    var stateService: MockStateService
    var subject: DefaultCustomHeadersService

    // MARK: Initialization

    init() {
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        keychainRepository = MockKeychainRepository()
        stateService = MockStateService()
        subject = DefaultCustomHeadersService(
            environmentService: environmentService,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository,
            stateService: stateService,
        )
    }

    // MARK: Tests - getCustomHeaders()

    /// `getCustomHeaders()` caches the headers so repeated calls for the same identifier read the
    /// keychain only once.
    @Test
    func getCustomHeaders_cachesHeadersById() async {
        environmentService.customHeadersId = "headers-id"
        keychainRepository.getCustomHeadersReturnValue = ["CF-Access-Client-Id": "id"]

        _ = await subject.getCustomHeaders()
        let result = await subject.getCustomHeaders()

        #expect(result == ["CF-Access-Client-Id": "id"])
        #expect(keychainRepository.getCustomHeadersCallsCount == 1)
    }

    /// `getCustomHeaders()` returns empty headers and logs an error when the keychain throws.
    @Test
    func getCustomHeaders_keychainThrows_logsErrorAndReturnsEmpty() async {
        let error = BitwardenTestError.example
        environmentService.customHeadersId = "headers-id"
        keychainRepository.getCustomHeadersThrowableError = error

        let result = await subject.getCustomHeaders()

        #expect(result.isEmpty)
        #expect(errorReporter.errors as? [BitwardenTestError] == [error])
    }

    /// `getCustomHeaders()` returns empty headers when the identifier is set but the keychain item
    /// is missing.
    @Test
    func getCustomHeaders_keychainValueMissing_returnsEmpty() async {
        environmentService.customHeadersId = "missing-from-keychain"
        keychainRepository.getCustomHeadersReturnValue = nil

        let result = await subject.getCustomHeaders()

        #expect(result.isEmpty)
    }

    /// `getCustomHeaders()` returns empty headers when no identifier is in the environment.
    @Test
    func getCustomHeaders_noId_returnsEmpty() async {
        environmentService.customHeadersId = nil

        let result = await subject.getCustomHeaders()

        #expect(result.isEmpty)
        #expect(!keychainRepository.getCustomHeadersCalled)
    }

    /// `getCustomHeaders()` re-reads the keychain when the environment's identifier changes.
    @Test
    func getCustomHeaders_newId_invalidatesCache() async {
        environmentService.customHeadersId = "headers-id-1"
        keychainRepository.getCustomHeadersReturnValue = ["Header-A": "1"]
        _ = await subject.getCustomHeaders()

        environmentService.customHeadersId = "headers-id-2"
        keychainRepository.getCustomHeadersReturnValue = ["Header-B": "2"]
        let result = await subject.getCustomHeaders()

        #expect(result == ["Header-B": "2"])
        #expect(keychainRepository.getCustomHeadersCallsCount == 2)
    }

    // MARK: Tests - getCustomHeaders(id:)

    /// `getCustomHeaders(id:)` returns the stored headers for the given identifier.
    @Test
    func getCustomHeadersId_returnsStoredHeaders() async throws {
        keychainRepository.getCustomHeadersReturnValue = ["CF-Access-Client-Secret": "secret"]

        let result = try await subject.getCustomHeaders(id: "headers-id")

        #expect(result == ["CF-Access-Client-Secret": "secret"])
        #expect(keychainRepository.getCustomHeadersReceivedId == "headers-id")
    }

    /// `getCustomHeaders(id:)` returns empty headers when nothing is stored for the identifier.
    @Test
    func getCustomHeadersId_valueMissing_returnsEmpty() async throws {
        keychainRepository.getCustomHeadersReturnValue = nil

        let result = try await subject.getCustomHeaders(id: "headers-id")

        #expect(result.isEmpty)
    }

    // MARK: Tests - removeCustomHeaders(id:)

    /// `removeCustomHeaders(id:)` deletes the keychain item when no account references the
    /// identifier.
    @Test
    func removeCustomHeaders_id_deletesKeychainItem() async throws {
        stateService.accounts = []

        try await subject.removeCustomHeaders(id: "headers-id")

        #expect(keychainRepository.deleteCustomHeadersReceivedId == "headers-id")
    }

    /// `removeCustomHeaders(id:)` keeps the keychain item when an account still references the
    /// identifier.
    @Test
    func removeCustomHeaders_id_sharedId_doesNotDeleteKeychainItem() async throws {
        let user1 = "1"
        stateService.accounts = [.fixture(profile: .fixture(userId: user1))]
        stateService.environmentURLs[user1] = EnvironmentURLData(
            base: URL(string: "https://example.com"),
            customHeadersId: "shared-headers-id",
        )

        try await subject.removeCustomHeaders(id: "shared-headers-id")

        #expect(!keychainRepository.deleteCustomHeadersCalled)
    }

    /// `removeCustomHeaders(id:)` keeps the keychain item when the pre-auth environment still
    /// references the identifier.
    @Test
    func removeCustomHeaders_id_preAuthReference_doesNotDeleteKeychainItem() async throws {
        stateService.accounts = []
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(
            base: URL(string: "https://example.com"),
            customHeadersId: "pre-auth-headers-id",
        )

        try await subject.removeCustomHeaders(id: "pre-auth-headers-id")

        #expect(!keychainRepository.deleteCustomHeadersCalled)
    }

    // MARK: Tests - removeCustomHeaders(userId:)

    /// `removeCustomHeaders(userId:)` deletes the keychain item when the removed user holds the
    /// last reference to the identifier.
    @Test
    func removeCustomHeaders_userId_lastReference_deletesKeychainItem() async throws {
        let user1 = "1"
        stateService.accounts = [.fixture(profile: .fixture(userId: user1))]
        stateService.environmentURLs[user1] = EnvironmentURLData(
            base: URL(string: "https://example.com"),
            customHeadersId: "only-headers-id",
        )

        try await subject.removeCustomHeaders(userId: user1)

        #expect(keychainRepository.deleteCustomHeadersReceivedId == "only-headers-id")
    }

    /// `removeCustomHeaders(userId:)` does nothing when the account has no custom headers
    /// identifier.
    @Test
    func removeCustomHeaders_userId_noId_doesNothing() async throws {
        let user1 = "1"
        stateService.accounts = [.fixture(profile: .fixture(userId: user1))]
        stateService.environmentURLs[user1] = EnvironmentURLData(
            base: URL(string: "https://example.com"),
        )

        try await subject.removeCustomHeaders(userId: user1)

        #expect(!keychainRepository.deleteCustomHeadersCalled)
    }

    /// `removeCustomHeaders(userId:)` keeps the keychain item when another account references the
    /// same identifier.
    @Test
    func removeCustomHeaders_userId_sharedId_doesNotDeleteKeychainItem() async throws {
        let user1 = "1"
        let user2 = "2"
        stateService.accounts = [
            .fixture(profile: .fixture(userId: user1)),
            .fixture(profile: .fixture(userId: user2)),
        ]
        stateService.environmentURLs[user1] = EnvironmentURLData(
            base: URL(string: "https://example.com"),
            customHeadersId: "shared-headers-id",
        )
        stateService.environmentURLs[user2] = EnvironmentURLData(
            base: URL(string: "https://example.com"),
            customHeadersId: "shared-headers-id",
        )

        try await subject.removeCustomHeaders(userId: user1)

        #expect(!keychainRepository.deleteCustomHeadersCalled)
    }

    // MARK: Tests - saveCustomHeaders(_:)

    /// `saveCustomHeaders(_:)` stores the headers in the keychain under a new identifier and
    /// returns the identifier.
    @Test
    func saveCustomHeaders_storesHeadersAndReturnsId() async throws {
        let headers = ["CF-Access-Client-Id": "id", "CF-Access-Client-Secret": "secret"]

        let id = try await subject.saveCustomHeaders(headers)

        let arguments = try #require(keychainRepository.setCustomHeadersReceivedArguments)
        #expect(arguments.headers == headers)
        #expect(arguments.id == id)
        #expect(!id.isEmpty)
    }

    /// `saveCustomHeaders(_:)` caches the saved headers so a following `getCustomHeaders()` for
    /// the same identifier doesn't read the keychain.
    @Test
    func saveCustomHeaders_cachesSavedHeaders() async throws {
        let headers = ["Header-A": "1"]

        let id = try await subject.saveCustomHeaders(headers)
        environmentService.customHeadersId = id
        let result = await subject.getCustomHeaders()

        #expect(result == headers)
        #expect(!keychainRepository.getCustomHeadersCalled)
    }
}
