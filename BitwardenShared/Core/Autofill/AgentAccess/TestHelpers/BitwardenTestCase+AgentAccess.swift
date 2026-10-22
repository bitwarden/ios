import Foundation

@testable import BitwardenShared

extension BitwardenTestCase {
    /// Runs work on a global dispatch thread, like the SDK calls its callbacks.
    @discardableResult
    func onSdkThread<T: Sendable>(_ work: @escaping @Sendable () -> T) async -> T {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: work())
            }
        }
    }

    /// Polls until the condition holds or the timeout passes.
    func waitUntil(timeout: TimeInterval = 2, _ condition: @escaping () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return condition()
    }
}
