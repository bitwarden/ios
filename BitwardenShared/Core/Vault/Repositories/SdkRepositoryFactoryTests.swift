import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - SdkRepositoryFactoryTests

class SdkRepositoryFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var cipherDataStore: MockCipherDataStore!
    var errorReporter: MockErrorReporter!
    var subject: SdkRepositoryFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherDataStore = MockCipherDataStore()
        errorReporter = MockErrorReporter()
        subject = DefaultSdkRepositoryFactory(cipherDataStore: cipherDataStore, errorReporter: errorReporter)
    }

    override func tearDown() {
        super.tearDown()

        cipherDataStore = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `makeCipherRepository(userId:)` makes a cipher repository for the given user ID.
    func test_makeCipherRepository() {
        let repository = subject.makeCipherRepository(userId: "1")
        XCTAssertTrue(repository is SdkCipherRepository)
    }
}
