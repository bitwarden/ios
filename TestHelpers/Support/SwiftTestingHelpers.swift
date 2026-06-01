// swiftlint:disable:this file_name

import Foundation
import Testing

// MARK: - waitForAsync

/// Wait for a condition asynchronously to be true. The test will fail if the condition isn't met
/// before the specified timeout.
///
/// - Parameters:
///   - condition: Return `true` to continue or `false` to keep waiting.
///   - timeout: How long to wait before failing.
///   - sourceLocation: The source location of the call site. Defaults to the location where this
///     function is called from.
///
@MainActor
public func waitForAsync(
    _ condition: @escaping () -> Bool,
    timeout: TimeInterval = 10.0,
    failureMessage: Comment = "waitForAsync condition wasn't met within the time limit",
    sourceLocation: SourceLocation = #_sourceLocation,
) async throws {
    let limit = Date(timeIntervalSinceNow: timeout)
    while !condition(), limit > Date() {
        try await Task.sleep(nanoseconds: 20_000_000)
    }
    #expect(condition(), failureMessage, sourceLocation: sourceLocation)
}

// MARK: - waitFor

/// Synchronously spins the main run loop until `condition` returns `true` or
/// the timeout elapses. Use this (instead of `waitForAsync`) when the code
/// under test uses `Timer.scheduledTimer`, which requires the run loop to tick
/// and is not driven by Swift Concurrency's task scheduler.
///
/// - Parameters:
///   - condition: Return `true` to stop waiting, `false` to keep spinning.
///   - timeout: How long to spin before failing. Defaults to 10 seconds.
///   - failureMessage: The message recorded on timeout.
///   - sourceLocation: The source location of the call site.
///
@MainActor
public func waitFor(
    _ condition: @autoclosure () -> Bool,
    timeout: TimeInterval = 10.0,
    failureMessage: Comment = "waitFor condition wasn't met within the time limit",
    sourceLocation: SourceLocation = #_sourceLocation,
) {
    let deadline = Date(timeIntervalSinceNow: timeout)
    while !condition(), Date() < deadline {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    }
    #expect(condition(), failureMessage, sourceLocation: sourceLocation)
}

// MARK: - withContinuationTimeout

/// Waits for a callback-based async operation to call its `resume` closure, recording a test
/// failure if `resume` is not called within the specified time.
///
/// Use this instead of `withCheckedContinuation` in tests to prevent indefinite hangs when the
/// expected callback is never called.
///
/// ```swift
/// await withContinuationTimeout { resume in
///     mockService.onComplete = { resume() }
///     subject.performAction()
/// }
/// ```
///
/// - Parameters:
///   - timeout: How long to wait before recording a failure. Defaults to 10 seconds.
///   - sourceLocation: The source location of the call site. Defaults to the location where this
///     function is called from.
///   - body: A closure that receives a `resume` callback. Call `resume()` to unblock the wait.
///
@MainActor
public func withContinuationTimeout(
    timeout: TimeInterval = 10.0,
    sourceLocation: SourceLocation = #_sourceLocation,
    body: (@escaping () -> Void) -> Void,
) async {
    struct TimedOut: Error {}

    do {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let stream = AsyncStream<Void> { continuation in
                body { continuation.yield(()) }
            }

            group.addTask {
                for await _ in stream {
                    return
                }
                throw CancellationError()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimedOut()
            }

            try await group.next()
            group.cancelAll()
        }
    } catch is TimedOut {
        Issue.record(
            "withContinuationTimeout: callback was not called within \(timeout)s",
            sourceLocation: sourceLocation,
        )
    } catch {
        // CancellationError from the stream-iterating task, thrown after the timeout fires and
        // the task group cancels it. Expected and safe to ignore.
    }
}
