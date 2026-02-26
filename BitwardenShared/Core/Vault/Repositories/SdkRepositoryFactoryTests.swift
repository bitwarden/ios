import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - SdkRepositoryFactoryTests

class SdkRepositoryFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var cipherDataStore: MockCipherDataStore!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: SdkRepositoryFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherDataStore = MockCipherDataStore()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        subject = DefaultSdkRepositoryFactory(
            cipherDataStore: cipherDataStore,
            errorReporter: errorReporter,
            stateService: stateService,
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherDataStore = nil
        errorReporter = nil
        stateService = nil
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
