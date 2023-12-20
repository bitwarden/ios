import BitwardenSdk
import XCTest

@testable import BitwardenShared

class CipherServiceTests: XCTestCase {
    // MARK: Properties

    var cipherDataStore: MockCipherDataStore!
    var subject: CipherService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherDataStore = MockCipherDataStore()

        subject = DefaultCipherService(
            cipherDataStore: cipherDataStore,
            stateService: MockStateService()
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherDataStore = nil
        subject = nil
    }

    // MARK: Tests

    /// `replaceCiphers(_:userId:)` replaces the persisted ciphers in the data store.
    func test_replaceCiphers() async throws {
        let ciphers: [CipherDetailsResponseModel] = [
            CipherDetailsResponseModel.fixture(id: "1", name: "Cipher 1"),
            CipherDetailsResponseModel.fixture(id: "2", name: "Cipher 2"),
        ]

        try await subject.replaceCiphers(ciphers, userId: "1")

        XCTAssertEqual(cipherDataStore.replaceCiphersValue, ciphers.map(Cipher.init))
        XCTAssertEqual(cipherDataStore.replaceCiphersUserId, "1")
    }
}
