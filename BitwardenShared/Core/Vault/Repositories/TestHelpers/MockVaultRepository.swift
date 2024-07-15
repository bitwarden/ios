import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

class MockVaultRepository: VaultRepository {
    // MARK: Properties

    var addCipherCiphers = [CipherView]()
    var addCipherResult: Result<Void, Error> = .success(())

    var ciphersSubject = CurrentValueSubject<[CipherListView], Error>([])
    var ciphersAutofillSubject = CurrentValueSubject<[CipherView], Error>([])
    var cipherDetailsSubject = CurrentValueSubject<CipherView?, Error>(.fixture())

    var clearTemporaryDownloadsCalled = false

    var deleteAttachmentId: String?
    var deleteAttachmentResult: Result<CipherView?, Error> = .success(.fixture())

    var deletedCipher = [String]()
    var deleteCipherResult: Result<Void, Error> = .success(())

    var doesActiveAccountHavePremiumCalled = false
    var doesActiveAccountHavePremiumResult: Result<Bool, Error> = .success(true)

    var downloadAttachmentAttachment: AttachmentView?
    var downloadAttachmentResult: Result<URL?, Error> = .success(nil)

    var fetchCipherId: String?
    var fetchCipherResult: Result<CipherView?, Error> = .success(nil)

    var fetchCipherOwnershipOptionsIncludePersonal: Bool? // swiftlint:disable:this identifier_name
    var fetchCipherOwnershipOptions = [CipherOwner]()

    var fetchCollectionsIncludeReadOnly: Bool?
    var fetchCollectionsResult: Result<[CollectionView], Error> = .success([])

    var fetchFoldersCalled = false
    var fetchFoldersResult: Result<[FolderView], Error> = .success([])

    var fetchSyncCalled = false
    var fetchSyncResult: Result<[VaultListSection]?, Error> = .success([])

    var getActiveAccountIdResult: Result<String, StateServiceError> = .failure(.noActiveAccount)

    var getDisableAutoTotpCopyResult: Result<Bool, Error> = .success(false)

    var hasUnassignedCiphersResult: Result<Bool, Error> = .success(false)

    var needsSyncCalled = false
    var needsSyncResult: Result<Bool, Error> = .success(false)

    var organizationsPublisherCalled = false
    var organizationsPublisherError: Error?
    var organizationsSubject = CurrentValueSubject<[Organization], Error>([])

    var refreshTOTPCodesResult: Result<[VaultListItem], Error> = .success([])
    var refreshedTOTPTime: Date?
    var refreshedTOTPCodes: [VaultListItem] = []
    var refreshTOTPCodeResult: Result<LoginTOTPState, Error> = .success(
        LoginTOTPState(authKeyModel: TOTPKeyModel(authenticatorKey: .base32Key))
    )
    var refreshedTOTPKeyConfig: TOTPKeyModel?

    var removeAccountIds = [String?]()

    var repromptRequiredForCipherResult: Result<Bool, Error> = .success(false)

    var restoredCipher = [CipherView]()
    var restoreCipherResult: Result<Void, Error> = .success(())

    var saveAttachmentFileName: String?
    var saveAttachmentResult: Result<CipherView, Error> = .success(.fixture())

    var searchCipherAutofillSubject = CurrentValueSubject<[CipherView], Error>([])

    var searchVaultListSubject = CurrentValueSubject<[VaultListItem], Error>([])
    var searchVaultListFilterType: VaultFilterType?

    var shareCipherCiphers = [CipherView]()
    var shareCipherResult: Result<Void, Error> = .success(())

    var shouldShowUnassignedCiphersAlert = false

    var softDeletedCipher = [CipherView]()
    var softDeleteCipherResult: Result<Void, Error> = .success(())

    var timeProvider: TimeProvider = MockTimeProvider(.currentTime)

    var updateCipherCiphers = [BitwardenSdk.CipherView]()
    var updateCipherResult: Result<Void, Error> = .success(())

    var updateCipherCollectionsCiphers = [CipherView]()
    var updateCipherCollectionsResult: Result<Void, Error> = .success(())

    var vaultListSubject = CurrentValueSubject<[VaultListSection], Error>([])
    var vaultListGroupSubject = CurrentValueSubject<[VaultListSection], Error>([])
    var vaultListFilter: VaultFilterType?

    // MARK: Computed Properties

    var refreshedTOTPKey: String? {
        refreshedTOTPKeyConfig?.rawAuthenticatorKey
    }

    // MARK: Methods

    func addCipher(_ cipher: BitwardenSdk.CipherView) async throws {
        addCipherCiphers.append(cipher)
        try addCipherResult.get()
    }

    func cipherPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherListView], Error>> {
        ciphersSubject.eraseToAnyPublisher().values
    }

    func cipherDetailsPublisher(id _: String) async throws -> AsyncThrowingPublisher<AnyPublisher<CipherView?, Error>> {
        cipherDetailsSubject.eraseToAnyPublisher().values
    }

    func ciphersAutofillPublisher(
        uri _: String?
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherView], Error>> {
        ciphersAutofillSubject.eraseToAnyPublisher().values
    }

    func clearTemporaryDownloads() {
        clearTemporaryDownloadsCalled = true
    }

    func deleteAttachment(withId attachmentId: String, cipherId _: String) async throws -> CipherView? {
        deleteAttachmentId = attachmentId
        return try deleteAttachmentResult.get()
    }

    func deleteCipher(_ id: String) async throws {
        deletedCipher.append(id)
        try deleteCipherResult.get()
    }

    func doesActiveAccountHavePremium() async throws -> Bool {
        doesActiveAccountHavePremiumCalled = true
        return try doesActiveAccountHavePremiumResult.get()
    }

    func downloadAttachment(_ attachment: AttachmentView, cipher _: CipherView) async throws -> URL? {
        downloadAttachmentAttachment = attachment
        return try downloadAttachmentResult.get()
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
        fetchFoldersCalled = true
        return try fetchFoldersResult.get()
    }

    func fetchSync(
        isManualRefresh _: Bool,
        filter _: VaultFilterType
    ) async throws -> [VaultListSection]? {
        fetchSyncCalled = true
        return try fetchSyncResult.get()
    }

    func getDisableAutoTotpCopy() async throws -> Bool {
        try getDisableAutoTotpCopyResult.get()
    }

    func hasUnassignedCiphers() async throws -> Bool {
        try hasUnassignedCiphersResult.get()
    }

    func needsSync() async throws -> Bool {
        needsSyncCalled = true
        return try needsSyncResult.get()
    }

    func organizationsPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[Organization], Error>> {
        organizationsPublisherCalled = true
        if let organizationsPublisherError {
            throw organizationsPublisherError
        }
        return organizationsSubject.eraseToAnyPublisher().values
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

    func repromptRequiredForCipher(id: String) async throws -> Bool {
        try repromptRequiredForCipherResult.get()
    }

    func restoreCipher(_ cipher: CipherView) async throws {
        restoredCipher.append(cipher)
        try restoreCipherResult.get()
    }

    func saveAttachment(cipherView _: CipherView, fileData _: Data, fileName: String) async throws -> CipherView {
        saveAttachmentFileName = fileName
        return try saveAttachmentResult.get()
    }

    func searchCipherAutofillPublisher(
        searchText _: String,
        filterType _: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherView], Error>> {
        searchCipherAutofillSubject.eraseToAnyPublisher().values
    }

    func searchVaultListPublisher(
        searchText _: String,
        group: VaultListGroup?,
        filterType filter: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Error>> {
        searchVaultListFilterType = filter
        return searchVaultListSubject.eraseToAnyPublisher().values
    }

    func shareCipher(_ cipher: CipherView, newOrganizationId: String, newCollectionIds: [String]) async throws {
        shareCipherCiphers.append(cipher)
        try shareCipherResult.get()
    }

    func shouldShowUnassignedCiphersAlert() async -> Bool {
        shouldShowUnassignedCiphersAlert
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

    func vaultListPublisher(
        filter: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListSection], Error>> {
        vaultListFilter = filter
        return vaultListSubject.eraseToAnyPublisher().values
    }

    func vaultListPublisher(
        group _: BitwardenShared.VaultListGroup,
        filter _: VaultFilterType
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListSection], Error>> {
        vaultListGroupSubject.eraseToAnyPublisher().values
    }
}

// MARK: - MockTimeProvider

class MockTimeProvider {
    enum TimeConfig {
        case currentTime
        case mockTime(Date)

        var date: Date {
            switch self {
            case .currentTime:
                return .now
            case let .mockTime(fixedDate):
                return fixedDate
            }
        }
    }

    var timeConfig: TimeConfig

    init(_ timeConfig: TimeConfig) {
        self.timeConfig = timeConfig
    }
}

extension MockTimeProvider: Equatable {
    static func == (_: MockTimeProvider, _: MockTimeProvider) -> Bool {
        true
    }
}

extension MockTimeProvider: TimeProvider {
    var presentTime: Date {
        timeConfig.date
    }

    func timeSince(_ date: Date) -> TimeInterval {
        presentTime.timeIntervalSince(date)
    }
}
