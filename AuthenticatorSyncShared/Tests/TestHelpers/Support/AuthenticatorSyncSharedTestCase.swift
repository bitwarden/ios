import XCTest

/// Base class for any tests in the AuthenticatorSyncShared framework.
///
open class AuthenticatorSyncSharedTestCase: XCTestCase {
    /// Asserts that an asynchronous block of code will throw an error. The test will fail if the
    /// block does not throw an error.
    ///
    /// - Note: This method does not rethrow the error thrown by `block`.
    ///
    /// - Parameters:
    ///     - block: The block to be executed. This block is run asynchronously.
    ///     - file: The file in which the failure occurred. Defaults to the file name of the test
    ///         case in which the function was called from.
    ///     - line: The line number in which the failure occurred. Defaults to the line number on
    ///         which this function was called from.
    ///
    open func assertAsyncThrows(
        _ block: () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            try await block()
            XCTFail("The block did not throw an error.", file: file, line: line)
        } catch {}
    }

    /// Asserts that an asynchronous block of code will throw a specific error. The test will fail
    /// if the block does not throw an error or if the error thrown does not equal the provided error.
    ///
    /// - Note: This method does not rethrow the error thrown by `block`.
    ///
    /// - Parameters:
    ///    - error: The specific error that must be thrown by `block`.
    ///    - block: The block to be executed. This block is run asynchronously.
    ///    - file: The file in which the failure occurred. Defaults to the file name of the test
    ///         case in which the function was called from.
    ///    - line: The line number in which the failure occurred. Defaults to the line number on
    ///         which this function was called from.
    ///
    open func assertAsyncThrows<E: Error & Equatable>(
        error: E,
        file: StaticString = #file,
        line: UInt = #line,
        _ block: () async throws -> Void
    ) async {
        do {
            try await block()
            XCTFail("The block did not throw an error.", file: file, line: line)
        } catch let caughtError as E {
            XCTAssertEqual(caughtError, error, file: file, line: line)
        } catch let caughtError {
            XCTFail(
                "The error caught (\(caughtError)) does not match the type of error provided (\(error)).",
                file: file,
                line: line
            )
        }
    }

    /// Asserts that an asynchronous block of code does not throw an error. The test will fail
    /// if the block throws an error.
    ///
    /// - Parameters:
    ///    - block: The block to be executed. This block is run asynchronously.
    ///    - file: The file in which the failure occurred. Defaults to the file name of the test
    ///         case in which the function was called from.
    ///    - line: The line number in which the failure occurred. Defaults to the line number on
    ///         which this function was called from.
    ///
    open func assertAsyncDoesNotThrow(
        _ block: () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            try await block()
        } catch {
            XCTFail("The block threw an error.", file: file, line: line)
        }
    }

    /// Wait for a condition to be true. The test will fail if the condition isn't met before the
    /// specified timeout.
    ///
    /// - Parameters:
    ///     - condition: Return `true` to continue or `false` to keep waiting.
    ///     - timeout: How long to wait before failing.
    ///     - failureMessage: Message to display when the condition fails to be met.
    ///     - file: The file in which the failure occurred. Defaults to the file name of the test
    ///         case in which the function was called from.
    ///     - line: The line number in which the failure occurred. Defaults to the line number on
    ///         which this function was called from.
    ///
    open func waitFor(
        _ condition: () -> Bool,
        timeout: TimeInterval = 10.0,
        failureMessage: String = "waitFor condition wasn't met within the time limit",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let start = Date()
        let limit = Date(timeIntervalSinceNow: timeout)

        while !condition(), limit > Date() {
            let next = Date(timeIntervalSinceNow: 0.2)
            RunLoop.current.run(mode: RunLoop.Mode.default, before: next)
        }

        warnIfNeeded(start: start, line: line)

        XCTAssert(condition(), failureMessage, file: file, line: line)
    }

    /// Wait for a condition to be true. The test will fail if the condition isn't met before the
    /// specified timeout.
    ///
    /// - Parameters:
    ///     - condition: An expression that evaluates to `true` to continue or `false` to keep waiting.
    ///     - timeout: How long to wait before failing.
    ///     - failureMessage: Message to display when the condition fails to be met.
    ///     - file: The file in which the failure occurred. Defaults to the file name of the test
    ///         case in which the function was called from.
    ///     - line: The line number in which the failure occurred. Defaults to the line number on
    ///         which this function was called from.
    ///
    open func waitFor(
        _ condition: @autoclosure () -> Bool,
        timeout: TimeInterval = 10.0,
        failureMessage: String = "waitFor condition wasn't met within the time limit",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        waitFor(
            condition,
            timeout: timeout,
            failureMessage: failureMessage,
            file: file,
            line: line
        )
    }

    /// Wait for a condition asynchronously to be true. The test will fail if the condition isn't met before the
    /// specified timeout.
    ///
    /// - Parameters:
    ///     - condition: Return `true` to continue or `false` to keep waiting.
    ///     - timeout: How long to wait before failing.
    ///     - failureMessage: Message to display when the condition fails to be met.
    ///     - file: The file in which the failure occurred. Defaults to the file name of the test
    ///         case in which the function was called from.
    ///     - line: The line number in which the failure occurred. Defaults to the line number on
    ///         which this function was called from.
    ///
    open func waitForAsync(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = 10.0,
        failureMessage: String = "waitForAsync condition wasn't met within the time limit",
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let start = Date()
        let limit = Date(timeIntervalSinceNow: timeout)

        while !condition(), limit > Date() {
            try await Task.sleep(nanoseconds: 2 * 100_000_000)
        }

        warnIfNeeded(start: start, line: line)

        XCTAssert(condition(), failureMessage, file: file, line: line)
    }

    /// Warns if `functionName` took more than `afterSeconds` to complete
    /// - Parameters:
    ///   - start: When `waitFor` started
    ///   - afterSeconds: The seconds that have passed since `start` to check against
    ///   - functionName: The function name
    ///   - line: File line were this was originated
    private func warnIfNeeded(
        start: Date,
        afterSeconds: Int = 3,
        functionName: String = #function,
        line: UInt = #line
    ) {
        // If the condition took more than 3 seconds to satisfy, add a warning to the logs to look into it.
        let elapsed = Date().timeIntervalSince(start)
        if elapsed > 3 {
            let numberFormatter = NumberFormatter()
            numberFormatter.maximumFractionDigits = 3
            numberFormatter.minimumFractionDigits = 3
            numberFormatter.minimumIntegerDigits = 1
            let elapsedString: String = numberFormatter.string(from: NSNumber(value: elapsed)) ?? "nil"
            print("warning: \(name) line \(line) `\(functionName)` took \(elapsedString) seconds")
        }
    }
}
