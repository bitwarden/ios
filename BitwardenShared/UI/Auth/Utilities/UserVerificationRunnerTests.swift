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
    func test_verifyWithAttempts_verified() async throws {
        let result = try await subject.verifyWithAttempts {
            .verified
        }

        XCTAssertEqual(result, .verified)
    }

    /// `verifyWithAttempts(verifyFunction:)` with `.cantPerform` inner function.
    func test_verifyWithAttempts_cantPerform() async throws {
        let result = try await subject.verifyWithAttempts {
            .unableToPerform
        }

        XCTAssertEqual(result, .unableToPerform)
    }

    /// `verifyWithAttempts(verifyFunction:)` with `.notVerified` inner function.
    func test_verifyWithAttempts_notVerified() async throws {
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
    func test_verifyWithAttempts_verifiedWhenInnerNotVerifiedAndVerified() async throws {
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
    func test_verifyWithAttempts_throws() async throws {
        await assertAsyncThrows(error: UserVerificationError.cancelled) {
            _ = try await subject.verifyWithAttempts {
                throw UserVerificationError.cancelled
            }
        }
    }

    /// `verifyInQueue(verifyFunctions:)` with three functions, first one can't perform and then verified.
    func test_verifyInQueue_verified() async throws {
        let verify1: VerifyFunction = {
            .unableToPerform
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
    func test_verifyInQueue_notVerified() async throws {
        let verify1: VerifyFunction = {
            .unableToPerform
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

    /// `verifyInQueue(verifyFunctions:)` with three functions that are unable to perform.
    func test_verifyInQueue_unableToPerform() async throws {
        let verify1: VerifyFunction = {
            .unableToPerform
        }

        let verify2: VerifyFunction = {
            .unableToPerform
        }

        let verify3: VerifyFunction = {
            .unableToPerform
        }

        let result = try await subject.verifyInQueue(verifyFunctions: [
            verify1,
            verify2,
            verify3,
        ])

        XCTAssertEqual(result, .unableToPerform)
    }

    /// `verifyInQueue(verifyFunctions:)` with no functions.
    func test_verifyInQueue_unableToPerformWhenNoFunctions() async throws {
        let result = try await subject.verifyInQueue(verifyFunctions: [])

        XCTAssertEqual(result, .unableToPerform)
    }

    /// `verifyInQueue(verifyFunctions:)` throwing.
    func test_verifyInQueue_throws() async throws {
        let verify: VerifyFunction = {
            throw UserVerificationError.cancelled
        }

        await assertAsyncThrows(error: UserVerificationError.cancelled) {
            _ = try await subject.verifyInQueue(verifyFunctions: [verify])
        }
    }
}
