import Foundation

/// Collects values delivered from other threads.
///
final class ThreadSafeLog<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [T] = []

    var values: [T] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ value: T) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(value)
    }
}
