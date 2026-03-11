import BitwardenKitMocks
import BitwardenSdk
import Combine
import TestHelpers
import Testing
import WatchConnectivity

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// swiftlint:disable file_length

// MARK: - WatchServiceTests

@MainActor
struct WatchServiceTests { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var cipherService: MockCipherService!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var organizationService: MockOrganizationService!
    var stateService: MockStateService!
    var vaultTimeoutService: MockVaultTimeoutService!
    var watchSession: MockWatchSession!
    var watchSessionFactory: MockWatchSessionFactory!
    var subject: DefaultWatchService!

    // MARK: Initialization

    init() async throws {
        cipherService = MockCipherService()
        clientService = MockClientService()
        configService = MockConfigService()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        organizationService = MockOrganizationService()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        watchSession = MockWatchSession()
        watchSession.underlyingIsPaired = true
        watchSession.underlyingIsWatchAppInstalled = true
        watchSession.underlyingActivationState = .activated

        watchSessionFactory = MockWatchSessionFactory()
        watchSessionFactory.isSupportedReturnValue = true
        watchSessionFactory.makeSessionReturnValue = watchSession

        stateService.activeAccount = .fixture(profile: .fixture(hasPremiumPersonally: true))
        stateService.connectToWatchSubject = CurrentValueSubject((nil, false))

        // Let the sync task in DefaultWatchService start up and run the initial pass to prevent
        // potential race conditions. This is done by waiting on `isSupported` to be called
        // and returning false so no initial sync is run, leaving the tests in a stable place to
        // start from.
        await withContinuationTimeout { resume in
            watchSessionFactory.isSupportedClosure = {
                resume()
                return false
            }

            subject = DefaultWatchService(
                cipherService: cipherService,
                clientService: clientService,
                configService: configService,
                environmentService: environmentService,
                errorReporter: errorReporter,
                organizationService: organizationService,
                stateService: stateService,
                watchSessionFactory: watchSessionFactory,
                vaultTimeoutService: vaultTimeoutService,
            )
        }
        watchSessionFactory.isSupportedClosure = nil
    }

    // MARK: handleMessage Tests

    /// When a `triggerSync` message is received, the service re-syncs.
    @Test
    func handleMessage_triggerSync_syncsCalled() async throws {
        clientService.mockVault.clientCiphers.decryptResult = { _ in
            .fixture(id: "cipher-1", login: .fixture(totp: "totp-secret"))
        }
        stateService.connectToWatchByUserId["1"] = true

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            stateService.connectToWatchByUserId["1"] = true
            cipherService.ciphersSubject.send([.fixture()])
            stateService.connectToWatchSubject.send(("1", true))
        }

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            Task {
                // Simulate a message from the watch via the internal handler.
                await subject.handleMessage(["actionMessage": "triggerSync"])
            }
        }

        #expect(watchSession.updateApplicationContextCallsCount == 2)
    }

    // MARK: isSupported Tests

    /// `isSupported()` returns `false` when the factory reports the session is not supported.
    @Test
    func isSupported_returnsFalse() {
        watchSessionFactory.isSupportedReturnValue = false
        #expect(subject.isSupported() == false)
    }

    /// `isSupported()` returns `true` when the factory reports the session is supported.
    @Test
    func isSupported_returnsTrue() {
        watchSessionFactory.isSupportedReturnValue = true
        #expect(subject.isSupported() == true)
    }

    // MARK: syncWithWatch Tests

    /// `syncWithWatch()` logs an unexpected error from `getActiveAccountId` and falls
    /// back to treating the user as logged out.
    @Test
    func syncWithWatch_getActiveAccountIdUnexpectedError_logsError() async throws {
        stateService.activeAccount = nil
        stateService.getActiveAccountIdError = BitwardenTestError.example
        stateService.lastUserShouldConnectToWatch = true

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }
            stateService.connectToWatchSubject.send((nil, false))
        }

        let dto = try decodedDTO(from: watchSession.updateApplicationContextReceivedApplicationContext)
        #expect(dto.state == .needLogin)
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    /// `syncWithWatch()` falls back to `getLastUserShouldConnectToWatch` without logging
    /// an error when `getConnectToWatch` throws `noActiveAccount`.
    @Test
    func syncWithWatch_getConnectToWatchNoActiveAccount_fallsBackSilently() async throws {
        stateService.connectToWatchResult = .failure(StateServiceError.noActiveAccount)
        stateService.lastUserShouldConnectToWatch = true

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }
            stateService.connectToWatchSubject.send(("1", true))
        }

        let dto = try decodedDTO(from: watchSession.updateApplicationContextReceivedApplicationContext)
        #expect(dto.state == .need2FAItem)
        #expect(errorReporter.errors.isEmpty)
    }

    /// `syncWithWatch()` falls back to `getLastUserShouldConnectToWatch` and logs an error
    /// when `getConnectToWatch` throws an unexpected error.
    @Test
    func syncWithWatch_getConnectToWatchUnexpectedError_logsErrorAndFallsBack() async throws {
        stateService.connectToWatchResult = .failure(BitwardenTestError.example)
        stateService.lastUserShouldConnectToWatch = true

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }
            stateService.connectToWatchSubject.send(("1", true))
        }

        let dto = try decodedDTO(from: watchSession.updateApplicationContextReceivedApplicationContext)
        #expect(dto.state == .need2FAItem)
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    /// `syncWithWatch()` sends a `.needLogin` state when there is no active account.
    @Test
    func syncWithWatch_noActiveAccount_sendsNeedLogin() async throws {
        stateService.activeAccount = nil
        stateService.lastUserShouldConnectToWatch = true

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            stateService.connectToWatchSubject.send((nil, true))
        }

        let dto = try decodedDTO(from: watchSession.updateApplicationContextReceivedApplicationContext)
        #expect(dto.state == .needLogin)
    }

    /// `syncWithWatch()` sends a `.needSetup` state when `shouldConnect` is `false`.
    @Test
    func syncWithWatch_shouldNotConnect_sendsNeedSetup() async throws {
        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            // First, establish the session by syncing with shouldConnect = true.
            stateService.connectToWatchByUserId["1"] = true
            stateService.connectToWatchSubject.send(("1", true))
        }

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            // Now update with shouldConnect = false — the existing session will be used.
            stateService.connectToWatchByUserId["1"] = false
            stateService.connectToWatchSubject.send(("1", false))
        }

        let dto = try decodedDTO(from: watchSession.updateApplicationContextReceivedApplicationContext)
        #expect(dto.state == .needSetup)
    }

    /// `syncWithWatch()` sends a `.needPremium` state when the user has no premium personally and
    /// no qualifying org.
    @Test
    func syncWithWatch_noPremium_sendsNeedPremium() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(hasPremiumPersonally: false))
        organizationService.fetchAllOrganizationsResult = .success([])

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            stateService.connectToWatchByUserId["1"] = true
            stateService.connectToWatchSubject.send(("1", true))
        }

        let dto = try decodedDTO(from: watchSession.updateApplicationContextReceivedApplicationContext)
        #expect(dto.state == .needPremium)
    }

    /// `syncWithWatch()` proceeds past the premium gate with sync when the user has premium via org.
    @Test
    func syncWithWatch_premiumViaOrg_proceedsToSync() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(hasPremiumPersonally: false))
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(enabled: true, usersGetPremium: true),
        ])

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            stateService.connectToWatchByUserId["1"] = true
            stateService.connectToWatchSubject.send(("1", true))
        }

        let dto = try decodedDTO(from: watchSession.updateApplicationContextReceivedApplicationContext)
        // Passed premium gate; empty TOTP list results in need2FAItem.
        #expect(dto.state == .need2FAItem)
    }

    /// `syncWithWatch()` sends a `.need2FAItem` state when there are no TOTP ciphers.
    @Test
    func syncWithWatch_noTotpCiphers_sendsNeed2FAItem() async throws {
        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            stateService.connectToWatchByUserId["1"] = true
            stateService.connectToWatchSubject.send(("1", true))
        }

        let dto = try decodedDTO(from: watchSession.updateApplicationContextReceivedApplicationContext)
        #expect(dto.state == .need2FAItem)
    }

    /// `syncWithWatch()` sends a `.valid` state and a list of ciphers if the user has premium and
    /// connect to watch enabled.
    @Test
    func syncWithWatch_validState_sendsWatchData() async throws {
        clientService.mockVault.clientCiphers.decryptResult = { _ in
            .fixture(id: "cipher-1", login: .fixture(totp: "totp-secret"))
        }

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            stateService.connectToWatchByUserId["1"] = true
            stateService.connectToWatchSubject.send(("1", true))
        }

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            cipherService.ciphersSubject.send([.fixture()])
        }

        let dto = try decodedDTO(from: watchSession.updateApplicationContextReceivedApplicationContext)
        #expect(dto.state == .valid)
        #expect(dto.ciphers?.count == 1)
        #expect(dto.ciphers?.first?.id == "cipher-1")
    }

    /// `syncWithWatch()` re-syncs with new data when ciphers update.
    @Test
    func syncWithWatch_ciphersUpdate_resyncs() async throws {
        clientService.mockVault.clientCiphers.decryptResult = { _ in
            .fixture(id: "cipher-1", login: .fixture(totp: "totp-secret"))
        }

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            stateService.connectToWatchByUserId["1"] = true
            stateService.connectToWatchSubject.send(("1", true))
        }

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            // Send a cipher update.
            cipherService.ciphersSubject.send([.fixture()])
        }

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            // Send a second cipher update.
            cipherService.ciphersSubject.send([.fixture(), .fixture(id: "cipher-2")])
        }

        let dto = try decodedDTO(from: watchSession.updateApplicationContextReceivedApplicationContext)
        #expect(dto.state == .valid)
        #expect(dto.ciphers?.count == 2)
    }

    /// `syncWithWatch()` does not sync ciphers when the vault is locked.
    @Test
    func syncWithWatch_vaultLocked_skipsCipherSync() async throws {
        var decryptCallCount = 0
        clientService.mockVault.clientCiphers.decryptResult = { _ in
            decryptCallCount += 1
            return .fixture(id: "cipher-1", login: .fixture(totp: "totp-secret"))
        }

        // Establish the session and confirm the decrypt path is reachable when unlocked.
        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            cipherService.ciphersSubject.send([.fixture()])
            stateService.connectToWatchByUserId["1"] = true
            stateService.connectToWatchSubject.send(("1", true))
        }
        let decryptCountAfterSetup = decryptCallCount
        #expect(decryptCountAfterSetup > 0)

        // Lock the vault and trigger another sync.
        vaultTimeoutService.isClientLocked["1"] = true
        stateService.connectToWatchSubject.send(("1", true))
        try await Task.sleep(nanoseconds: 10_000_000)

        // Confirm no additional decrypt attempts.
        #expect(decryptCallCount == decryptCountAfterSetup)
    }

    /// `syncWithWatch()` syncs ciphers after the vault becomes unlocked.
    @Test
    func syncWithWatch_vaultUnlocked_syncsAfterUnlock() async throws {
        clientService.mockVault.clientCiphers.decryptResult = { _ in
            .fixture(id: "cipher-1", login: .fixture(totp: "totp-secret"))
        }

        // Start locked — no sync should occur.
        vaultTimeoutService.isClientLocked["1"] = true
        stateService.connectToWatchByUserId["1"] = true
        stateService.connectToWatchSubject.send(("1", true))
        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(watchSession.updateApplicationContextCallsCount == 0)

        // Unlock the vault — the publisher emits, triggering a fresh sync.
        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            cipherService.ciphersSubject.send([.fixture()])
            vaultTimeoutService.isClientLocked["1"] = false
            vaultTimeoutService.vaultLockStatusSubject.send(
                VaultLockStatus(isVaultLocked: false, userId: "1"),
            )
        }

        let dto = try decodedDTO(from: watchSession.updateApplicationContextReceivedApplicationContext)
        #expect(dto.state == .valid)
    }

    // MARK: connectToWatchPublisher Tests

    /// When the publisher emits twice, only the latest sync task remains active.
    @Test
    func connectToWatchPublisher_newUser_cancelsPreviousTask() async throws {
        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            stateService.connectToWatchByUserId["1"] = true
            stateService.connectToWatchSubject.send(("1", true))
        }

        await withContinuationTimeout { resume in
            watchSession.updateApplicationContextClosure = { _ in resume() }

            // Second emission should cancel the first task and create a new one.
            stateService.connectToWatchSubject.send(("2", true))
        }

        // Each emission syncs; the second emission produces at least one additional sync.
        #expect(watchSession.updateApplicationContextCallsCount == 2)
    }

    // MARK: Helpers

    /// Decodes a `WatchDTO` from the last-sent `updateApplicationContext` call.
    private func decodedDTO(from context: [String: Any]?) throws -> WatchDTO {
        let sentData = try #require(context)
        let compressedData = try #require(sentData.values.first as? NSData)
        let decompressed = try compressedData.decompressed(using: .lzfse) as Data
        return try MessagePackDecoder().decode(WatchDTO.self, from: decompressed)
    }
}
