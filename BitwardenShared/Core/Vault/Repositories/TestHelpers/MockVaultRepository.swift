import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import Combine
import Foundation
import TestHelpers

@testable import BitwardenShared

class MockVaultRepository: VaultRepository {
    // MARK: Properties

    var addCipherCiphers = [CipherView]()
    var addCipherResult: Result<Void, Error> = .success(())

    var canShowVaultFilter = true

    var ciphersAutofillPublisherUriCalled: String?
    var ciphersSubject = CurrentValueSubject<[CipherListView], Error>([])
    var ciphersAutofillPublisherCalledWithGroup: VaultListGroup?
    var ciphersAutofillSubject = CurrentValueSubject<VaultListData, Error>(VaultListData())
    var cipherDetailsSubject = CurrentValueSubject<CipherView?, Error>(.fixture())

    var clearTemporaryDownloadsCalled = false

    // swiftlint:disable:next identifier_name
    var createAutofillListExcludedCredentialSectionResult: Result<VaultListSection, Error> = .failure(
        BitwardenTestError.example
    )

    var deleteAttachmentId: String?
    var deleteAttachmentResult: Result<CipherView?, Error> = .success(.fixture())

    var deletedCipher = [String]()
    var deleteCipherResult: Result<Void, Error> = .success(())

    var doesActiveAccountHavePremiumCalled = false
    var doesActiveAccountHavePremiumResult: Bool = true

    var downloadAttachmentAttachment: AttachmentView?
    var downloadAttachmentResult: Result<URL?, Error> = .success(nil)

    var fetchCipherId: String?
    var fetchCipherResult: Result<CipherView?, Error> = .success(nil)

    var fetchCipherOwnershipOptionsIncludePersonal: Bool? // swiftlint:disable:this identifier_name
    var fetchCipherOwnershipOptions = [CipherOwner]()

    var fetchCollectionsIncludeReadOnly: Bool?
    var fetchCollectionsResult: Result<[CollectionView], Error> = .success([])

    var fetchFolderResult: Result<FolderView?, Error> = .success(nil)

    var fetchFoldersCalled = false
    var fetchFoldersResult: Result<[FolderView], Error> = .success([])

    var fetchOrganizationResult: Result<Organization?, Error> = .success(nil)

    var fetchSyncCalled = false
    var fetchSyncForceSync: Bool?
    var fetchSyncIsPeriodic: Bool?
    var fetchSyncResult: Result<Void, Error> = .success(())

    var getActiveAccountIdResult: Result<String, StateServiceError> = .failure(.noActiveAccount)

    var getDisableAutoTotpCopyResult: Result<Bool, Error> = .success(false)

    var getTOTPKeyIfAllowedToCopyResult: Result<String?, Error> = .success(nil)

    var getItemTypesUserCanCreateResult: [BitwardenShared.CipherType] = CipherType.canCreateCases

    var isVaultEmptyCalled = false
    var isVaultEmptyResult: Result<Bool, Error> = .success(false)

    var needsSyncCalled = false
    var needsSyncResult: Result<Bool, Error> = .success(false)

    var organizationsPublisherCalled = false
    var organizationsPublisherError: Error?
    var organizationsSubject = CurrentValueSubject<[Organization], Error>([])

    var refreshTOTPCodesCalled = false
    var refreshTOTPCodesResult: Result<[VaultListItem], Error> = .success([])
    var refreshedTOTPTime: Date?
    var refreshedTOTPCodes: [VaultListItem] = []
    var refreshTOTPCodeResult: Result<LoginTOTPState, Error> = .success(
        LoginTOTPState(authKeyModel: TOTPKeyModel(authenticatorKey: .standardTotpKey))
    )
    var refreshedTOTPKeyConfig: TOTPKeyModel?

    var removeAccountIds = [String?]()

    var repromptRequiredForCipherResult: Result<Bool, Error> = .success(false)

    var restoredCipher = [CipherView]()
    var restoreCipherResult: Result<Void, Error> = .success(())

    var saveAttachmentFileName: String?
    var saveAttachmentResult: Result<CipherView, Error> = .success(.fixture())

    var searchCipherAutofillPublisherCalledWithGroup: VaultListGroup? // swiftlint:disable:this identifier_name
    var searchCipherAutofillSubject = CurrentValueSubject<VaultListData, Error>(VaultListData())

    var searchVaultListSubject = CurrentValueSubject<[VaultListItem], Error>([])
    var searchVaultListFilterType: VaultListFilter?

    var shareCipherCiphers = [CipherView]()
    var shareCipherResult: Result<Void, Error> = .success(())

    var softDeletedCipher = [CipherView]()
    var softDeleteCipherResult: Result<Void, Error> = .success(())

    var timeProvider: TimeProvider = MockTimeProvider(.currentTime)

    var updateCipherCiphers = [BitwardenSdk.CipherView]()
    var updateCipherResult: Result<Void, Error> = .success(())

    var updateCipherCollectionsCiphers = [CipherView]()
    var updateCipherCollectionsResult: Result<Void, Error> = .success(())

    var vaultListSubject = CurrentValueSubject<VaultListData, Error>(VaultListData())
    var vaultListFilter: VaultListFilter?

    // MARK: Computed Properties

    var refreshedTOTPKey: String? {
        refreshedTOTPKeyConfig?.rawAuthenticatorKey
    }

    // MARK: Methods

    func addCipher(_ cipher: BitwardenSdk.CipherView) async throws {
        addCipherCiphers.append(cipher)
        try addCipherResult.get()
    }

    func canShowVaultFilter() async -> Bool {
        canShowVaultFilter
    }

    func cipherPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[CipherListView], Error>> {
        ciphersSubject.eraseToAnyPublisher().values
    }

    func cipherDetailsPublisher(id _: String) async throws -> AsyncThrowingPublisher<AnyPublisher<CipherView?, Error>> {
        cipherDetailsSubject.eraseToAnyPublisher().values
    }

    func ciphersAutofillPublisher(
        availableFido2CredentialsPublisher: AnyPublisher<[BitwardenSdk.CipherView]?, Error>,
        mode: BitwardenShared.AutofillListMode,
        group: BitwardenShared.VaultListGroup?,
        rpID: String?,
        uri: String?
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>> {
        ciphersAutofillPublisherUriCalled = uri
        ciphersAutofillPublisherCalledWithGroup = group
        return ciphersAutofillSubject.eraseToAnyPublisher().values
    }

    func clearTemporaryDownloads() {
        clearTemporaryDownloadsCalled = true
    }

    func createAutofillListExcludedCredentialSection(from cipher: CipherView) async throws -> VaultListSection {
        try createAutofillListExcludedCredentialSectionResult.get()
    }

    func deleteAttachment(withId attachmentId: String, cipherId _: String) async throws -> CipherView? {
        deleteAttachmentId = attachmentId
        return try deleteAttachmentResult.get()
    }

    func deleteCipher(_ id: String) async throws {
        deletedCipher.append(id)
        try deleteCipherResult.get()
    }

    func doesActiveAccountHavePremium() async -> Bool {
        doesActiveAccountHavePremiumCalled = true
        return doesActiveAccountHavePremiumResult
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

    func fetchFolder(withId id: String) async throws -> BitwardenSdk.FolderView? {
        try fetchFolderResult.get()
    }

    func fetchFolders() async throws -> [FolderView] {
        fetchFoldersCalled = true
        return try fetchFoldersResult.get()
    }

    func fetchOrganization(withId id: String) async throws -> BitwardenShared.Organization? {
        try fetchOrganizationResult.get()
    }

    func fetchSync(
        forceSync: Bool,
        filter _: VaultFilterType,
        isPeriodic: Bool
    ) async throws {
        fetchSyncCalled = true
        fetchSyncForceSync = forceSync
        fetchSyncIsPeriodic = isPeriodic
        try fetchSyncResult.get()
    }

    func getDisableAutoTotpCopy() async throws -> Bool {
        try getDisableAutoTotpCopyResult.get()
    }

    func getItemTypesUserCanCreate() async -> [BitwardenShared.CipherType] {
        getItemTypesUserCanCreateResult
    }

    func getTOTPKeyIfAllowedToCopy(cipher: CipherView) async throws -> String? {
        try getTOTPKeyIfAllowedToCopyResult.get()
    }

    func needsSync() async throws -> Bool {
        needsSyncCalled = true
        return try needsSyncResult.get()
    }

    func isVaultEmpty() async throws -> Bool {
        isVaultEmptyCalled = true
        return try isVaultEmptyResult.get()
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
        refreshTOTPCodesCalled = true
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

    func searchCipherAutofillPublisher( // swiftlint:disable:this function_parameter_count
        availableFido2CredentialsPublisher: AnyPublisher<[BitwardenSdk.CipherView]?, Error>,
        mode: BitwardenShared.AutofillListMode,
        filter: BitwardenShared.VaultListFilter,
        group: BitwardenShared.VaultListGroup?,
        rpID: String?,
        searchText: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>> {
        searchCipherAutofillPublisherCalledWithGroup = group
        return searchCipherAutofillSubject.eraseToAnyPublisher().values
    }

    func searchVaultListPublisher(
        searchText _: String,
        group: VaultListGroup?,
        filter: BitwardenShared.VaultListFilter
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Error>> {
        searchVaultListFilterType = filter
        return searchVaultListSubject.eraseToAnyPublisher().values
    }

    func shareCipher(_ cipher: CipherView, newOrganizationId: String, newCollectionIds: [String]) async throws {
        shareCipherCiphers.append(cipher)
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

    func vaultListPublisher(
        filter: BitwardenShared.VaultListFilter
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>> {
        vaultListFilter = filter
        return vaultListSubject.eraseToAnyPublisher().values
    }
}
