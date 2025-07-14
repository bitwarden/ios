import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - VaultListSectionsBuilderFactoryTests

class VaultListSectionsBuilderFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var clientService: MockClientService!
    var errorReporter: MockErrorReporter!
    var subject: VaultListSectionsBuilderFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        subject = DefaultVaultListSectionsBuilderFactory(clientService: clientService, errorReporter: errorReporter)
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `make(withData:)` makes a vault list sections builderwith the prepared data.
    func test_make() {
        let builder = subject.make(withData: VaultListPreparedData())
        XCTAssertTrue(builder is DefaultVaultListSectionsBuilder)
    }
}
