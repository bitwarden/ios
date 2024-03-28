import AuthenticatorShared
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
open class AuthenticatorTestCase: XCTestCase {
    /// The window being used for testing. Defaults to a new window with the same size as `UIScreen.main.bounds`.
    public var window: UIWindow!

    @MainActor
    override open class func setUp() {
        if UIDevice.current.name != "iPhone 15 Pro" {
            assertionFailure(
                """
                Tests must be run using the iPhone 15 Pro simulator. Snapshot tests depend on using the correct device.
                """
            )
        }

        // Apply default appearances for snapshot tests.
//        UI.applyDefaultAppearances()
    }

    /// Executes any logic that should be applied before each test runs.
    ///
    @MainActor
    override open func setUp() {
        super.setUp()
        UI.animated = false
        UI.sizeCategory = .large
        window = UIWindow(frame: UIScreen.main.bounds)
        window.layer.speed = 100
    }

    /// Executes any logic that should be applied after each test runs.
    ///
    override open func tearDown() {
        super.tearDown()
        UI.animated = false
        window = nil
    }

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
        _ block: () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
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

    /// Make a `UIViewController` the root view controller in the test window. Allows testing
    /// changes to the navigation stack when they would ordinarily be invisible to the testing
    /// environment.
    ///
    /// - Parameters:
    ///     - viewController: The `UIViewController` to make root view controller.
    ///
    open func setKeyWindowRoot(viewController: UIViewController) {
        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }

    /// Nests a `UIView` within a root view controller in the test window. Allows testing
    /// changes to the view that require the view to exist within a window or are dependent on safe
    /// area layouts.
    ///
    /// - Parameters:
    ///     - view: The `UIView` to add to a root view controller.
    ///
    open func setKeyWindowRoot(view: UIView) {
        let viewController = UIViewController()
        viewController.view.addConstrained(subview: view)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
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

        // If the condition took more than 3 seconds to satisfy, add a warning to the logs to look into it.
        let elapsed = Date().timeIntervalSince(start)
        if elapsed > 3 {
            let numberFormatter = NumberFormatter()
            numberFormatter.maximumFractionDigits = 3
            numberFormatter.minimumFractionDigits = 3
            numberFormatter.minimumIntegerDigits = 1
            let elapsedString: String = numberFormatter.string(from: NSNumber(value: elapsed)) ?? "nil"
            print("warning: \(name) line \(line) `waitFor` took \(elapsedString) seconds")
        }

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
}
