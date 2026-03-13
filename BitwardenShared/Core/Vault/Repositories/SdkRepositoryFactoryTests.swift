import BitwardenKitMocks
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SdkRepositoryFactoryTests

class SdkRepositoryFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var cipherDataStore: MockCipherDataStore!
    var errorReporter: MockErrorReporter!
    var serverCommunicationConfigStateService: MockServerCommunicationConfigStateService!
    var subject: SdkRepositoryFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherDataStore = MockCipherDataStore()
        errorReporter = MockErrorReporter()
        serverCommunicationConfigStateService = MockServerCommunicationConfigStateService()
        subject = DefaultSdkRepositoryFactory(
            cipherDataStore: cipherDataStore,
            errorReporter: errorReporter,
            serverCommunicationConfigStateService: serverCommunicationConfigStateService,
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherDataStore = nil
        errorReporter = nil
        serverCommunicationConfigStateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `makeCipherRepository(userId:)` makes a cipher repository for the given user ID.
    func test_makeCipherRepository() {
        let repository = subject.makeCipherRepository(userId: "1")
        XCTAssertTrue(repository is SdkCipherRepository)
    }

    /// `makeServerCommunicationConfigRepository()` makes a server communication config repository.
    func test_makeServerCommunicationConfigRepository() {
        let repository = subject.makeServerCommunicationConfigRepository()
        XCTAssertTrue(repository is SdkServerCommunicationConfigRepository)
    }
}
