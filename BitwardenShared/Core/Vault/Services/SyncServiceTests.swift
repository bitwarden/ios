import XCTest

@testable import BitwardenShared

import BitwardenSdk

class SyncServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var clientCrypto: MockClientCrypto!
    var errorReporter: MockErrorReporter!
    var folderService: MockFolderService!
    var stateService: MockStateService!
    var subject: SyncService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        clientCrypto = MockClientCrypto()
        errorReporter = MockErrorReporter()
        folderService = MockFolderService()
        stateService = MockStateService()

        subject = DefaultSyncService(
            clientCrypto: clientCrypto,
            errorReporter: errorReporter,
            folderService: folderService,
            stateService: stateService,
            syncAPIService: APIService(client: client)
        )
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        clientCrypto = nil
        errorReporter = nil
        folderService = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `clearCachedData()` removes any data cached by the service.
    func test_clearCachedData() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)
        stateService.activeAccount = .fixture()

        var iterator = subject.syncResponsePublisher().values.makeAsyncIterator()
        _ = await iterator.next()

        Task {
            try await subject.fetchSync()
        }
        var publisherValue = await iterator.next()
        try XCTAssertNotNil(XCTUnwrap(publisherValue))

        subject.clearCachedData()
        publisherValue = await iterator.next()
        try XCTAssertNil(XCTUnwrap(publisherValue))
    }

    /// `fetchSync()` performs the sync API request.
    func test_fetchSync() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync()

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].method, .get)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/sync")
    }

    /// `fetchSync()` replaces the list of the user's folders.
    func test_fetchSync_folders() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync()

        XCTAssertEqual(
            folderService.replaceFoldersFolders,
            [
                FolderResponseModel(
                    id: "3270afb7-e3d7-495a-8867-c66cf272f795",
                    name: "Social",
                    revisionDate: Date(year: 2023, month: 10, day: 9, hour: 3, minute: 44, second: 59)
                ),
            ]
        )
        XCTAssertEqual(folderService.replaceFoldersUserId, "1")
    }

    /// `fetchSync()` throws an error if the request fails.
    func test_fetchSync_error() async throws {
        client.result = .httpFailure()
        stateService.activeAccount = .fixture()

        await assertAsyncThrows {
            try await subject.fetchSync()
        }
    }

    /// `fetchSync()` initializes the SDK for decrypting organization ciphers.
    func test_fetchSync_initializeOrgCrypto() async throws {
        client.result = .httpSuccess(testData: .syncWithProfileOrganizations)
        stateService.activeAccount = .fixture()

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
        stateService.activeAccount = .fixture()

        try await subject.fetchSync()

        XCTAssertTrue(errorReporter.errors.last is InitializeOrgCryptoError)
    }

    /// `fetchSync()` initializes the SDK for decrypting organization ciphers with an empty
    /// dictionary if the user isn't a part of any organizations.
    func test_fetchSync_initializesOrgCrypto_noOrganizations() async throws {
        client.result = .httpSuccess(testData: .syncWithProfile)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync()

        XCTAssertEqual(
            clientCrypto.initializeOrgCryptoRequest,
            InitOrgCryptoRequest(organizationKeys: [:])
        )
    }
}
