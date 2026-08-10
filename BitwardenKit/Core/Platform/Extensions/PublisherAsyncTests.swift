import BitwardenKit
import Combine
import Testing

struct PublisherAsyncTests {
    // MARK: Tests

    /// `asyncCompactMap(_:)` maps the output of a publisher, discarding any `nil` values.
    @Test
    func asyncCompactMap() async {
        var receivedValues = [Int]()

        let sequence = [1, 2, 3, 4, 5]
        for await value in sequence.publisher.asyncCompactMap({ $0 % 2 == 0 ? $0 : nil }).values {
            receivedValues.append(value)
        }

        #expect(receivedValues == [2, 4])
    }

    /// `asyncMap(_:)` maps the output of a publisher.
    @Test
    func asyncMap() async {
        var receivedValues = [Int]()

        let sequence = [1, 2, 3, 4, 5]
        for await value in sequence.publisher.asyncMap({ $0 * 2 }).values {
            receivedValues.append(value)
        }

        #expect(receivedValues == [2, 4, 6, 8, 10])
    }
}
