import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

class MockVaultRepository: VaultRepository {
    // MARK: Properties

    var addCipherCiphers = [BitwardenSdk.CipherView]()
    var addCipherResult: Result<Void, Error> = .success(())
    var ciphersSubject = CurrentValueSubject<[CipherListView], Error>([])
    var cipherDetailsSubject = CurrentValueSubject<BitwardenSdk.CipherView, Never>(.fixture())
    var deletedCipher = [String]()
    var deleteCipherResult: Result<Void, Error> = .success(())
    var doesActiveAccountHavePremiumCalled = false
    var fetchCipherId: String?
    var fetchCipherResult: Result<CipherView?, Error> = .success(nil)
    var fetchCipherOwnershipOptionsIncludePersonal: Bool? // swiftlint:disable:this identifier_name
    var fetchCipherOwnershipOptions = [CipherOwner]()
    var fetchCollectionsIncludeReadOnly: Bool?
    var fetchCollectionsResult: Result<[CollectionView], Error> = .success([])
    var fetchFoldersResult: Result<[FolderView], Error> = .success([])
    var fetchSyncCalled = false
    var fetchSyncResult: Result<Void, Error> = .success(())
    var getActiveAccountIdResult: Result<String, StateServiceError> = .failure(.noActiveAccount)
    var hasPremiumResult: Result<Bool, Error> = .success(true)
    var organizationsSubject = CurrentValueSubject<[Organization], Error>([])
    var refreshTOTPCodesResult: Result<[VaultListItem], Error> = .success([])
    var refreshedTOTPTime: Date?
    var refreshedTOTPCodes: [VaultListItem] = []
    var refreshTOTPCodeResult: Result<LoginTOTPState, Error> = .success(
        LoginTOTPState(
            authKeyModel: TOTPKeyModel(authenticatorKey: .base32Key)!,
            totpTime: .currentTime
        )
    )
    var refreshedTOTPKeyConfig: TOTPKeyModel?
    var removeAccountIds = [String?]()
    var searchCipherSubject = CurrentValueSubject<[VaultListItem], Error>([])
    var shareCipherResult: Result<Void, Error> = .success(())
    var sharedCiphers = [CipherView]()
    var softDeletedCipher = [CipherView]()
    var softDeleteCipherResult: Result<Void, Error> = .success(())
    var mockTimeProvider = MockTimeProvider()
    var updateCipherCiphers = [BitwardenSdk.CipherView]()
    var updateCipherResult: Result<Void, Error> = .success(())
    var updateCipherCollectionsCiphers = [CipherView]()
    var updateCipherCollectionsResult: Result<Void, Error> = .success(())
    var validatePasswordPasswords = [String]()
    var validatePasswordResult: Result<Bool, Error> = .success(true)
    var vaultListSubject = CurrentValueSubject<[VaultListSection], Never>([])
    var vaultListGroupSubject = CurrentValueSubject<[VaultListItem], Never>([])
    var vaultListFilter: VaultFilterType?

    // MARK: Computed Properties

    var refreshedTOTPKey: String? {
        refreshedTOTPKeyConfig?.rawAuthenticatorKey
    }

    var timeProvider: any TimeProvider {
        mockTimeProvider
    }

    // MARK: Methods

    func addCipher(_ cipher: BitwardenSdk.CipherView) async throws {
        addCipherCiphers.append(cipher)
        try addCipherResult.get()
    }

    func cipherPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherListView], Error>> {
        ciphersSubject.eraseToAnyPublisher().values
    }

    func cipherDetailsPublisher(id _: String) -> AsyncPublisher<AnyPublisher<BitwardenSdk.CipherView, Never>> {
        cipherDetailsSubject.eraseToAnyPublisher().values
    }

    func deleteCipher(_ id: String) async throws {
        deletedCipher.append(id)
        try deleteCipherResult.get()
    }

    func doesActiveAccountHavePremium() async throws -> Bool {
        doesActiveAccountHavePremiumCalled = true
        return try hasPremiumResult.get()
    }

    func fetchCipher(withId id: String) async throws -> CipherView? {
        fetchCipherId = id
        return try fetchCipherResult.get()
    }

    func fetchCipherOwnershipOptions(includePersonal: Bool) async throws -> [CipherOwner] {
        fetchCipherOwnershipOptionsIncludePersonal = includePersonal
        return fetchCipherOwnershipOptions
    }

    func fetchCollections(includeReadOnly: Bool) async throws -> [CollectionView] {
        fetchCollectionsIncludeReadOnly = includeReadOnly
        return try fetchCollectionsResult.get()
    }

    func fetchFolders() async throws -> [FolderView] {
        try fetchFoldersResult.get()
    }

    func fetchSync(isManualRefresh _: Bool) async throws {
        fetchSyncCalled = true
        try fetchSyncResult.get()
    }

    func organizationsPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[Organization], Error>> {
        organizationsSubject.eraseToAnyPublisher().values
    }

    func refreshTOTPCode(for key: BitwardenShared.TOTPKeyModel) async throws -> BitwardenShared.LoginTOTPState {
        refreshedTOTPKeyConfig = key
        return try refreshTOTPCodeResult.get()
    }

    func refreshTOTPCodes(for items: [BitwardenShared.VaultListItem]) async throws -> [BitwardenShared.VaultListItem] {
        refreshedTOTPTime = timeProvider.presentTime
        refreshedTOTPCodes = items
        return try refreshTOTPCodesResult.get()
    }

    func remove(userId: String?) async {
        removeAccountIds.append(userId)
    }

    func searchCipherPublisher(
        searchText: String,
        filterType: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Error>> {
        searchCipherSubject.eraseToAnyPublisher().values
    }

    func shareCipher(_ cipher: CipherView) async throws {
        sharedCiphers.append(cipher)
        try shareCipherResult.get()
    }

    func softDeleteCipher(_ cipher: CipherView) async throws {
        softDeletedCipher.append(cipher)
        try softDeleteCipherResult.get()
    }

    func updateCipher(_ cipher: BitwardenSdk.CipherView) async throws {
        updateCipherCiphers.append(cipher)
        try updateCipherResult.get()
    }

    func updateCipherCollections(_ cipher: CipherView) async throws {
        updateCipherCollectionsCiphers.append(cipher)
        try updateCipherCollectionsResult.get()
    }

    func validatePassword(_ password: String) async throws -> Bool {
        validatePasswordPasswords.append(password)
        return try validatePasswordResult.get()
    }

    func vaultListPublisher(
        filter: VaultFilterType
    ) -> AsyncPublisher<AnyPublisher<[BitwardenShared.VaultListSection], Never>> {
        vaultListFilter = filter
        return vaultListSubject.eraseToAnyPublisher().values
    }

    func vaultListPublisher(
        group _: BitwardenShared.VaultListGroup
    ) -> AsyncPublisher<AnyPublisher<[VaultListItem], Never>> {
        vaultListGroupSubject.eraseToAnyPublisher().values
    }
}

// MARK: - MockTimeProvider

struct MockTimeProvider {
    var mockTime: Date?
}

extension MockTimeProvider: Equatable {
    static func == (lhs: MockTimeProvider, rhs: MockTimeProvider) -> Bool {
        true
    }
}

extension MockTimeProvider: TimeProvider {
    var presentTime: Date {
        mockTime ?? .now
    }

    func timeSince(_ date: Date) -> TimeInterval {
        presentTime.timeIntervalSince(date)
    }
}
