import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(forSeconds delay: Double, tolerance: Double = 1) async throws {
        if #available(iOS 16.0, *) {
            try await sleep(for: .seconds(delay), tolerance: .seconds(tolerance))
        } else {
            try await sleep(nanoseconds: UInt64(delay * Double(NSEC_PER_SEC)))
        }
    }
}
