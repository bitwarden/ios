import Foundation

public extension Task where Success == Never, Failure == Never {
    /// Suspends the current task for at least the specified duration in seconds.
    ///
    /// - Parameters:
    ///   - delay: The number of seconds to sleep.
    ///   - tolerance: The acceptable tolerance for the sleep duration in seconds. Defaults to 1 second.
    ///
    static func sleep(forSeconds delay: Double, tolerance: Double = 1) async throws {
        if #available(iOS 16.0, *) {
            try await sleep(for: .seconds(delay), tolerance: .seconds(tolerance))
        } else {
            try await sleep(nanoseconds: UInt64(delay * Double(NSEC_PER_SEC)))
        }
    }
}
