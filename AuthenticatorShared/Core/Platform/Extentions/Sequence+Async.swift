import Foundation

extension Sequence {
    /// Performs an operation on each element of a sequence.
    /// Each operation is performed serially in order.
    ///
    /// - Parameters:
    ///   - operation: The closure to run on each element.
    ///
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }

    /// Maps the elements of an array with an async Transform.
    ///
    /// - Parameter transform: An asynchronous function mapping the sequence element.
    ///
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}
