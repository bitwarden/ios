import Foundation

extension Sequence {
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
