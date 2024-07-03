import Foundation
import XCTest

/// Errors that the invocation mockers can throw.
public enum InvocationMockerError: LocalizedError {
    case paramVerificationFailed
    case resultNotSet

    public var errorDescription: String? {
        switch self {
        case .paramVerificationFailed:
            return "The verification of the parameter failed."
        case .resultNotSet:
            return "The result of the InvocationMocker has not been set yet."
        }
    }
}

/// A mocker of a func invocation that has one parameter.
/// This is useful for tests where we need to verify a correct parameter is passed on invocation.
class InvocationMocker<TParam> {
    var invokedParam: TParam?
    var called = false

    /// Executes the `verification` and if it passes returns the `result`, throwing otherwise.
    /// - Parameter param: The parameter of the function to invoke.
    /// - Returns: Returns the result setup.
    func invoke(param: TParam?) {
        called = true
        invokedParam = param
    }

    /// Asserts by verifying the parameter which was passed to the invoked function.
    /// - Parameters:
    ///   - verification: Verification to run.
    ///   - message: Message if fails.
    ///   - file: File where this was originated.
    ///   - line: Line number where this was originated.
    func assert(
        verification: (TParam?) -> Bool,
        _ message: @autoclosure () -> String = "\(TParam.self) verification failed",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssert(verification(invokedParam), message(), file: file, line: line)
    }

    /// Asserts by verifying the parameter which was passed to the invoked function.
    /// This unwraps the parameter, but if can't be done then fails.
    /// - Parameters:
    ///   - verification: Verification to run.
    ///   - message: Message if fails.
    ///   - file: File where this was originated.
    ///   - line: Line number where this was originated.
    func assertUnwrapping(
        verification: (TParam) -> Bool,
        _ message: @autoclosure () -> String = "\(TParam.self) verification failed",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let invokedParam else {
            XCTFail("\(TParam.self) verification failed because parameter has not been set.")
            return
        }
        XCTAssert(verification(invokedParam), message(), file: file, line: line)
    }
}

/// A mocker of a func invocation that has one parameter, a result and can throw.
/// This is useful for tests where we need to verify a correct parameter is passed
/// to return the correct result.
class InvocationMockerWithThrowingResult<TParam, TResult> {
    var called = false
    var result: Result<TResult, Error> = .failure(InvocationMockerError.resultNotSet)
    var verification: (TParam) -> Bool = { _ in true }

    /// Sets up a verification to be executed and needs to pass in order to return the result.
    /// - Parameter verification: Verification to run.
    /// - Returns: `Self` for fluent coding.
    func withVerification(verification: @escaping (TParam) -> Bool) -> Self {
        self.verification = verification
        return self
    }

    /// Sets up the result that will be returned if the verification passes.
    /// - Parameter result: The result to return.
    /// - Returns: `Self` for fluent coding
    @discardableResult
    func withResult(_ result: TResult) -> Self {
        withResult(.success(result))
    }

    /// Sets up the error to throw if the verification passes.
    /// - Parameter error: The error to throw.
    /// - Returns: `Self` for fluent coding
    @discardableResult
    func throwing(_ error: Error) -> Self {
        withResult(.failure(error))
    }

    /// Sets up the result that will be returned if the verification passes.
    /// - Parameter result: The result to return.
    /// - Returns: `Self` for fluent coding
    @discardableResult
    func withResult(_ result: Result<TResult, Error>) -> Self {
        self.result = result
        return self
    }

    /// Executes the `verification` and if it passes returns the `result`, throwing otherwise.
    /// - Parameter param: The parameter of the function to invoke.
    /// - Returns: Returns the result setup.
    func invoke(param: TParam) throws -> TResult {
        called = true
        guard verification(param) else {
            XCTFail("\(TParam.self) verification failed.")
            throw InvocationMockerError.paramVerificationFailed
        }
        return try result.get()
    }
}
