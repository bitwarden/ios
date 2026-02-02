import LocalAuthentication
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - LocalAuthServiceTests

class LocalAuthServiceTests: BitwardenTestCase {
    // MARK: Properties

    var laContext: MockLAContext!
    var subject: LocalAuthService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        laContext = MockLAContext()
        subject = DefaultLocalAuthService()
    }

    override func tearDown() {
        super.tearDown()

        laContext = nil
        subject = nil
    }

    // MARK: Tests

    /// `getDeviceAuthStatus(_:)`  with authorized LAContext
    func test_getDeviceAuthStatus_authorized() {
        laContext.canEvaluatePolicyResult = true

        let result = subject.getDeviceAuthStatus(laContext)

        XCTAssertEqual(result, .authorized)
    }

    /// `getDeviceAuthStatus(_:)`  when LAContext can't evaluate policy
    /// and its error is nil
    func test_getDeviceAuthStatus_notDetermined() {
        laContext.canEvaluatePolicyResult = false

        let result = subject.getDeviceAuthStatus(laContext)

        XCTAssertEqual(result, .notDetermined)
    }

    /// `getDeviceAuthStatus(_:)`  when LAContext can't evaluate policy
    /// and its error is nil
    func test_getDeviceAuthStatus_unknownErrorOnNotLAError() {
        laContext.canEvaluatePolicyResult = false
        laContext.canEvaluatePolicyError = BitwardenTestError.example

        let result = subject.getDeviceAuthStatus(laContext)

        XCTAssertEqual(result, .unknownError(BitwardenTestError.example.localizedDescription))
    }

    /// `getDeviceAuthStatus(_:)`  when LAContext can't evaluate policy
    /// and its error is nil
    func test_getDeviceAuthStatus_unknownErrorOnLAErrorNotExpected() {
        laContext.canEvaluatePolicyResult = false
        laContext.canEvaluatePolicyError = LAError(LAError.Code.invalidContext)

        let result = subject.getDeviceAuthStatus(laContext)

        XCTAssertEqual(result, .unknownError(LAError(LAError.Code.invalidContext).localizedDescription))
    }

    /// `getDeviceAuthStatus(_:)`  when LAContext can't evaluate policy
    /// and its error is nil
    func test_getDeviceAuthStatus_cancelled() {
        laContext.canEvaluatePolicyResult = false
        laContext.canEvaluatePolicyError = LAError(LAError.Code.userCancel)

        let result = subject.getDeviceAuthStatus(laContext)

        XCTAssertEqual(result, .cancelled)
    }

    /// `getDeviceAuthStatus(_:)`  when LAContext can't evaluate policy
    /// and its error is nil
    func test_getDeviceAuthStatus_passcodeNotSet() {
        laContext.canEvaluatePolicyResult = false
        laContext.canEvaluatePolicyError = LAError(LAError.Code.passcodeNotSet)

        let result = subject.getDeviceAuthStatus(laContext)

        XCTAssertEqual(result, .passcodeNotSet)
    }

    /// `evaluateDeviceOwnerPolicy(_:for:reason:)`
    /// when status is authorized
    func test_evaluateDeviceOwnerPolicy_true() async throws {
        let reason = "reason"

        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .authorized, reason: reason)

        XCTAssertTrue(result)
        XCTAssertEqual(reason, laContext.evaluatePolicyLocalizedReason)
    }

    /// `evaluateDeviceOwnerPolicy(_:for:reason:)`
    /// when status is authorized but evaluates wrongly
    func test_evaluateDeviceOwnerPolicy_falseEvaluation() async throws {
        let reason = "reason"
        laContext.evaluatePolicyResult = .success(false)

        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .authorized, reason: reason)

        XCTAssertFalse(result)
        XCTAssertEqual(reason, laContext.evaluatePolicyLocalizedReason)
    }

    /// `evaluateDeviceOwnerPolicy(_:for:reason:)`
    /// when status is authorized but evaluation throws `LAError.Code.userCancel`
    func test_evaluateDeviceOwnerPolicy_throwsCancel() async throws {
        let reason = "reason"
        laContext.evaluatePolicyResult = .failure(LAError(LAError.Code.userCancel))

        await assertAsyncThrows(error: LocalAuthError.cancelled) {
            _ = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .authorized, reason: reason)
        }
    }

    /// `evaluateDeviceOwnerPolicy(_:for:reason:)`
    /// when status is authorized but evaluation throws random error
    func test_evaluateDeviceOwnerPolicy_onRandomError() async throws {
        let reason = "reason"
        laContext.evaluatePolicyResult = .failure(BitwardenTestError.example)

        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .authorized, reason: reason)

        XCTAssertFalse(result)
        XCTAssertEqual(reason, laContext.evaluatePolicyLocalizedReason)
    }

    /// `evaluateDeviceOwnerPolicy(_:for:reason:)`
    /// when LAContext evaluates correctly and status is not determined
    func test_evaluateDeviceOwnerPolicy_statusNotDetermined() async throws {
        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .notDetermined, reason: "")

        XCTAssertFalse(result)
    }

    /// `evaluateDeviceOwnerPolicy(_:for:reason:)`
    /// when status is passcode not set
    func test_evaluateDeviceOwnerPolicy_statusPasscodeNotSet() async throws {
        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .passcodeNotSet, reason: "")

        XCTAssertFalse(result)
    }

    /// `evaluateDeviceOwnerPolicy(_:for:reason:)`
    /// when status is cancelled
    func test_evaluateDeviceOwnerPolicy_statusCancelled() async throws {
        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .cancelled, reason: "")

        XCTAssertFalse(result)
    }

    /// `evaluateDeviceOwnerPolicy(_:for:reason:)`
    /// when status is unknown error
    func test_evaluateDeviceOwnerPolicy_statusUnknownError() async throws {
        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .unknownError(""), reason: "")

        XCTAssertFalse(result)
    }
}

class MockLAContext: LAContext {
    var canEvaluatePolicyError: Error?
    var canEvaluatePolicyResult: Bool = true
    var evaluatePolicyLocalizedReason: String?
    var evaluatePolicyResult: Result<Bool, Error> = .success(true)

    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        if let canEvaluatePolicyError {
            error?.pointee = canEvaluatePolicyError as NSError
        }
        return canEvaluatePolicyResult
    }

    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        evaluatePolicyLocalizedReason = localizedReason
        return try evaluatePolicyResult.get()
    }
}
