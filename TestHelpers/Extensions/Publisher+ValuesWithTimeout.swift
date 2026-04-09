import Combine
import Foundation

/// An error thrown when a publisher times out while awaiting values.
public struct PublisherTimeoutError: Error {}

public extension Publisher where Failure == Error {
    /// Returns an async sequence of the publisher's values with a timeout.
    ///
    /// This is useful in tests where you want to await publisher values without risking test hangs
    /// if the publisher never emits.
    ///
    /// - Parameter timeout: The maximum time interval to wait for values, in seconds. Defaults to 10 seconds.
    /// - Returns: An async throwing publisher that emits values or throws `PublisherTimeoutError` on timeout.
    ///
    func valuesWithTimeout(
        _ timeout: TimeInterval = 10,
    ) -> AsyncThrowingPublisher<Publishers.Timeout<Self, DispatchQueue>> {
        self
            .timeout(
                .seconds(timeout),
                scheduler: DispatchQueue.main,
                customError: { PublisherTimeoutError() },
            )
            .values
    }
}
