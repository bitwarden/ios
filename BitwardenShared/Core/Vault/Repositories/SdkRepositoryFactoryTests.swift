import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SdkRepositoryFactoryTests

class SdkRepositoryFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var cipherDataStore: MockCipherDataStore!
    var serverCommunicationConfigStateService: MockServerCommunicationConfigStateService!
    var stateService: MockLocalUserDataStateService!
    var subject: SdkRepositoryFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherDataStore = MockCipherDataStore()
        serverCommunicationConfigStateService = MockServerCommunicationConfigStateService()
        stateService = MockLocalUserDataStateService()
        subject = DefaultSdkRepositoryFactory(
            cipherDataStore: cipherDataStore,
            serverCommunicationConfigStateService: serverCommunicationConfigStateService,
            stateService: stateService,
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherDataStore = nil
        serverCommunicationConfigStateService = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `makeRepositories(userId:)` returns repositories with a cipher and local user data key state repository.
    func test_makeRepositories() {
        let repositories = subject.makeRepositories(userId: "1")
        XCTAssertNotNil(repositories.cipher)
        XCTAssertNil(repositories.folder)
        XCTAssertNil(repositories.userKeyState)
        XCTAssertNotNil(repositories.localUserDataKeyState)
    }

    /// `makeServerCommunicationConfigRepository()` makes a server communication config repository.
    func test_makeServerCommunicationConfigRepository() {
        let repository = subject.makeServerCommunicationConfigRepository()
        XCTAssertTrue(repository is SdkServerCommunicationConfigRepository)
    }
}
