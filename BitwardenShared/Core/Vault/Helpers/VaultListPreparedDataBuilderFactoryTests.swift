import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - VaultListPreparedDataBuilderFactoryTests

class VaultListPreparedDataBuilderFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var cipherService: MockCipherService!
    var clientService: MockClientService!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var timeProvider: MockTimeProvider!
    var subject: VaultListPreparedDataBuilderFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.currentTime)
        subject = DefaultVaultListPreparedDataBuilderFactory(
            cipherService: cipherService,
            clientService: clientService,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider,
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        clientService = nil
        errorReporter = nil
        stateService = nil
        timeProvider = nil
        subject = nil
    }

    // MARK: Tests

    /// `make()` returns a new `DefaultVaultListPreparedDataBuilder`.
    func test_make() {
        let result = subject.make()
        XCTAssertTrue(result is DefaultVaultListPreparedDataBuilder)
    }
}
