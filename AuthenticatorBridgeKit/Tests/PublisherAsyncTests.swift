import Combine
import XCTest

@testable import AuthenticatorBridgeKit

class PublisherAsyncTests: AuthenticatorBridgeKitTestCase {
    // MARK: Properties

    var cancellable: AnyCancellable?

    // MARK: Setup & Teardown

    override func tearDown() {
        super.tearDown()

        cancellable = nil
    }

    // MARK: Tests

    /// `asyncCompactMap(_:)` maps the output of a publisher, discarding any `nil` values.
    func test_asyncCompactMap() {
        var receivedValues = [Int]()

        let expectation = expectation(description: #function)
        let sequence = [1, 2, 3, 4, 5]
        cancellable = sequence
            .publisher
            .asyncCompactMap { $0 % 2 == 0 ? $0 : nil }
            .collect()
            .sink { values in
                receivedValues = values
                expectation.fulfill()
            }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(receivedValues, [2, 4])
    }

    /// `asyncMap(_:)` maps the output of a publisher.
    func test_asyncMap() {
        var receivedValues = [Int]()

        let expectation = expectation(description: #function)
        let sequence = [1, 2, 3, 4, 5]
        cancellable = sequence
            .publisher
            .asyncMap { $0 * 2 }
            .collect()
            .sink { values in
                receivedValues = values
                expectation.fulfill()
            }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(receivedValues, [2, 4, 6, 8, 10])
    }
}
