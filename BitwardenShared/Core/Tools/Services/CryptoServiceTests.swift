import XCTest

@testable import BitwardenShared

class CryptoServiceTests: BitwardenTestCase {
    // MARK: Properties

    var randomNumberGenerator: MockRandomNumberGenerator!
    var subject: DefaultCryptoService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        randomNumberGenerator = MockRandomNumberGenerator()

        subject = DefaultCryptoService(randomNumberGenerator: randomNumberGenerator)
    }

    override func tearDown() {
        super.tearDown()

        randomNumberGenerator = nil
        subject = nil
    }

    // MARK: Tests

    /// `randomString(length:)` returns a random string of the specified length.
    func test_randomString() throws {
        randomNumberGenerator.randomNumberResults = [0]
        try XCTAssertEqual(subject.randomString(length: 1), "a")

        randomNumberGenerator.randomNumberResults = [18]
        try XCTAssertEqual(subject.randomString(length: 1), "s")

        randomNumberGenerator.randomNumberResults = [35]
        try XCTAssertEqual(subject.randomString(length: 1), "0")

        randomNumberGenerator.randomNumberResults = [36]
        try XCTAssertEqual(subject.randomString(length: 1), "a")

        randomNumberGenerator.randomNumberResults = [UInt.max, UInt.max - 36]
        try XCTAssertEqual(subject.randomString(length: 1), "p")

        randomNumberGenerator.randomNumberResults = [10, 20, 30, 40, 50, 60, 80, 100]
        try XCTAssertEqual(subject.randomString(length: 8), "ku5eoyi3")
    }
}

class MockRandomNumberGenerator: RandomNumberGenerator {
    var randomNumberResults = [UInt]()

    func randomNumber() throws -> UInt {
        guard !randomNumberResults.isEmpty else {
            throw CryptoServiceError.randomNumberGenerationFailed(-1)
        }
        return randomNumberResults.removeFirst()
    }
}
