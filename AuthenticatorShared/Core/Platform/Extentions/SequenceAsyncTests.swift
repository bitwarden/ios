@testable import AuthenticatorShared

import XCTest

final class SequenceAsyncTests: AuthenticatorTestCase {
    /// `asyncMap` correctly maps each element.
    func test_asyncMap_success() async {
        let input = [1, 2, 3]
        let output = await input.asyncMap { number in
            await asyncDouble(number)
        }
        XCTAssertEqual(output, [2, 4, 6])
    }

    /// `asyncMap` correctly propagates errors.
    func test_asyncMap_error() async {
        let input = [1, 2, 3]
        await assertAsyncThrows {
            _ = try await input.asyncMap { number in
                try await asyncDoubleWithError(number)
            }
        }
    }

    /// Helper function to double a number asynchronously.
    ///
    ///  - Parameter number: an `Int` to double.
    ///  - Returns: The number multiplied by 2.
    ///
    private func asyncDouble(_ number: Int) async -> Int {
        number * 2
    }

    /// Helper function to double a number asynchronously and throw an error for a specific case.
    ///
    ///  - Parameters:
    ///     - number: an `Int` to double.
    ///     - errorCase: The `Int` for which to throw an error. Default is 2.
    ///  - Returns: The number multiplied by 2.
    ///
    private func asyncDoubleWithError(_ number: Int, errorCase: Int = 2) async throws -> Int {
        if number == errorCase {
            throw NSError(domain: "TestError", code: 0, userInfo: nil)
        }
        return number * 2
    }
}
