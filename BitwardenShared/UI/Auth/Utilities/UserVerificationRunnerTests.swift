import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - UserVerificationRunnerTests

class UserVerificationRunnerTests: BitwardenTestCase {
    // MARK: Types

    typealias VerifyFunction = () async throws -> UserVerificationResult

    // MARK: Properties

    var subject: UserVerificationRunner!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DefaultUserVerificationRunner()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `verifyWithAttempts(verifyFunction:)` with `.Verified` inner function.
    func test_verifyWithAttempts_verified_when_passed_closure_returns_verified() async throws {
        let result = try await subject.verifyWithAttempts {
            .verified
        }

        XCTAssertEqual(result, .verified)
    }

    /// `verifyWithAttempts(verifyFunction:)` with `.cantPerform` inner function.
    func test_verifyWithAttempts_cantPerform_when_passed_closure_returns_cantPerform() async throws {
        let result = try await subject.verifyWithAttempts {
            .cantPerform
        }

        XCTAssertEqual(result, .cantPerform)
    }

    /// `verifyWithAttempts(verifyFunction:)` with `.notVerified` inner function.
    func test_verifyWithAttempts_notVerified_when_passed_closure_returns_notVerified_all_the_times() async throws {
        var attempt = 0
        let result = try await subject.verifyWithAttempts {
            attempt += 1
            return .notVerified
        }

        XCTAssertEqual(result, .notVerified)
        XCTAssertEqual(attempt, 5)
    }

    /// `verifyWithAttempts(verifyFunction:)` with inner function returning
    /// 3 times `notVerified` and then `.verified`.
    func test_verifyWithAttempts_verified_when_passed_closure_returns_notVerified_and_then_verified() async throws {
        var attempt = 0
        let result = try await subject.verifyWithAttempts {
            attempt += 1
            guard attempt >= 3 else {
                return .notVerified
            }
            return .verified
        }

        XCTAssertEqual(result, .verified)
        XCTAssertGreaterThanOrEqual(attempt, 3)
    }

    /// `verifyWithAttempts(verifyFunction:)` throwing.
    func test_verifyWithAttempts_throws_when_passed_closure_throws() async throws {
        await assertAsyncThrows(error: UserVerificationError.cancelled) {
            _ = try await subject.verifyWithAttempts {
                throw UserVerificationError.cancelled
            }
        }
    }

    /// `verifyInQueue(verifyFunctions:)` with three functions, first one can't perform and then verified.
    func test_verifyInQueue_verified_on_second_function() async throws {
        let verify1: VerifyFunction = {
            .cantPerform
        }

        let verify2: VerifyFunction = {
            .verified
        }

        let verify3: VerifyFunction = {
            .notVerified
        }

        let result = try await subject.verifyInQueue(verifyFunctions: [
            verify1,
            verify2,
            verify3,
        ])

        XCTAssertEqual(result, .verified)
    }

    /// `verifyInQueue(verifyFunctions:)` with three functions, first one can't perform and then not verified.
    func test_verifyInQueue_not_verified_on_second_function() async throws {
        let verify1: VerifyFunction = {
            .cantPerform
        }

        let verify2: VerifyFunction = {
            .notVerified
        }

        let verify3: VerifyFunction = {
            .verified
        }

        let result = try await subject.verifyInQueue(verifyFunctions: [
            verify1,
            verify2,
            verify3,
        ])

        XCTAssertEqual(result, .notVerified)
    }

    /// `verifyInQueue(verifyFunctions:)` with three functions that can't perform.
    func test_verifyInQueue_cantPerform_when_none_of_the_functions_can_perform() async throws {
        let verify1: VerifyFunction = {
            .cantPerform
        }

        let verify2: VerifyFunction = {
            .cantPerform
        }

        let verify3: VerifyFunction = {
            .cantPerform
        }

        let result = try await subject.verifyInQueue(verifyFunctions: [
            verify1,
            verify2,
            verify3,
        ])

        XCTAssertEqual(result, .cantPerform)
    }

    /// `verifyInQueue(verifyFunctions:)` with no functions.
    func test_verifyInQueue_cantPerform_when_no_functions() async throws {
        let result = try await subject.verifyInQueue(verifyFunctions: [])

        XCTAssertEqual(result, .cantPerform)
    }

    /// `verifyInQueue(verifyFunctions:)` throwing.
    func test_verifyInQueue_throws_when_passed_closure_throws() async throws {
        let verify: VerifyFunction = {
            throw UserVerificationError.cancelled
        }

        await assertAsyncThrows(error: UserVerificationError.cancelled) {
            _ = try await subject.verifyInQueue(verifyFunctions: [verify])
        }
    }
}
