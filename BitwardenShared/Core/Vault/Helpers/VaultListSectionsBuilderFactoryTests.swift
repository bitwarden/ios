import BitwardenKitMocks
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - VaultListSectionsBuilderFactoryTests

class VaultListSectionsBuilderFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var clientService: MockClientService!
    var collectionHelper: MockCollectionHelper!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var subject: VaultListSectionsBuilderFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        collectionHelper = MockCollectionHelper()
        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        subject = DefaultVaultListSectionsBuilderFactory(
            clientService: clientService,
            collectionHelper: collectionHelper,
            configService: configService,
            errorReporter: errorReporter,
        )
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        collectionHelper = nil
        configService = nil
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
