import LocalAuthentication
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

    /// `getDeviceAuthStatus(suppliedContext:)`  with authorized LAContext
    func test_getDeviceAuthStatus_authorized() {
        laContext.canEvaluatePolicyResult = true

        let result = subject.getDeviceAuthStatus(laContext)

        XCTAssertEqual(result, .authorized)
    }

    /// `getDeviceAuthStatus(suppliedContext:)`  when LAContext can't evaluate policy
    /// and its error is nil
    func test_getDeviceAuthStatus_notDetermined_because_error_nil() {
        laContext.canEvaluatePolicyResult = false

        let result = subject.getDeviceAuthStatus(laContext)

        XCTAssertEqual(result, .notDetermined)
    }

    /// `getDeviceAuthStatus(suppliedContext:)`  when LAContext can't evaluate policy
    /// and its error is nil
    func test_getDeviceAuthStatus_unknown_error_because_error_is_not_LAError() {
        laContext.canEvaluatePolicyResult = false
        laContext.canEvaluatePolicyError = BitwardenTestError.example

        let result = subject.getDeviceAuthStatus(laContext)

        XCTAssertEqual(result, .unknownError(BitwardenTestError.example.localizedDescription))
    }

    /// `getDeviceAuthStatus(suppliedContext:)`  when LAContext can't evaluate policy
    /// and its error is nil
    func test_getDeviceAuthStatus_unknown_error_because_LAError_is_not_expected() {
        laContext.canEvaluatePolicyResult = false
        laContext.canEvaluatePolicyError = LAError(LAError.Code.invalidContext)

        let result = subject.getDeviceAuthStatus(laContext)

        XCTAssertEqual(result, .unknownError(LAError(LAError.Code.invalidContext).localizedDescription))
    }

    /// `getDeviceAuthStatus(suppliedContext:)`  when LAContext can't evaluate policy
    /// and its error is nil
    func test_getDeviceAuthStatus_cancelled_because_LAError_is_userCancel() {
        laContext.canEvaluatePolicyResult = false
        laContext.canEvaluatePolicyError = LAError(LAError.Code.userCancel)

        let result = subject.getDeviceAuthStatus(laContext)

        XCTAssertEqual(result, .cancelled)
    }

    /// `getDeviceAuthStatus(suppliedContext:)`  when LAContext can't evaluate policy
    /// and its error is nil
    func test_getDeviceAuthStatus_passcodeNotSet_because_LAError_is_passcodeNotSet() {
        laContext.canEvaluatePolicyResult = false
        laContext.canEvaluatePolicyError = LAError(LAError.Code.passcodeNotSet)

        let result = subject.getDeviceAuthStatus(laContext)

        XCTAssertEqual(result, .passcodeNotSet)
    }

    /// `evaluateDeviceOwnerPolicy(suppliedContext:,deviceAuthStatus:,localizedReason:)`
    /// when status is authorized
    func test_evaluateDeviceOwnerPolicy_true_when_authorized_and_evaluates_correctly() async throws {
        let reason = "reason"

        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .authorized, because: reason)

        XCTAssertTrue(result)
        XCTAssertEqual(reason, laContext.evaluatePolicyLocalizedReason)
    }

    /// `evaluateDeviceOwnerPolicy(suppliedContext:,deviceAuthStatus:,localizedReason:)`
    /// when status is authorized but evaluates wrongly
    func test_evaluateDeviceOwnerPolicy_false_when_authorized_and_evaluates_incorrectly() async throws {
        let reason = "reason"
        laContext.evaluatePolicyResult = .success(false)

        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .authorized, because: reason)

        XCTAssertFalse(result)
        XCTAssertEqual(reason, laContext.evaluatePolicyLocalizedReason)
    }

    /// `evaluateDeviceOwnerPolicy(suppliedContext:,deviceAuthStatus:,localizedReason:)`
    /// when status is authorized but evaluation throws `LAError.Code.userCancel`
    func test_evaluateDeviceOwnerPolicy_throws_cancel_when_authorized_LAError_userCancel() async throws {
        let reason = "reason"
        laContext.evaluatePolicyResult = .failure(LAError(LAError.Code.userCancel))

        await assertAsyncThrows(error: LocalAuthError.cancelled) {
            _ = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .authorized, because: reason)
        }
    }

    /// `evaluateDeviceOwnerPolicy(suppliedContext:,deviceAuthStatus:,localizedReason:)`
    /// when status is authorized but evaluation throws random error
    func test_evaluateDeviceOwnerPolicy_false_when_authorized_random_error() async throws {
        let reason = "reason"
        laContext.evaluatePolicyResult = .failure(BitwardenTestError.example)

        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .authorized, because: reason)

        XCTAssertFalse(result)
        XCTAssertEqual(reason, laContext.evaluatePolicyLocalizedReason)
    }

    /// `evaluateDeviceOwnerPolicy(suppliedContext:,deviceAuthStatus:,localizedReason:)`
    /// when LAContext evaluates correctly and status is not determined
    func test_evaluateDeviceOwnerPolicy_false_when_status_not_determined() async throws {
        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .notDetermined, because: "")

        XCTAssertFalse(result)
    }

    /// `evaluateDeviceOwnerPolicy(suppliedContext:,deviceAuthStatus:,localizedReason:)`
    /// when status is passcode not set
    func test_evaluateDeviceOwnerPolicy_false_when_status_passcodeNotSet() async throws {
        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .passcodeNotSet, because: "")

        XCTAssertFalse(result)
    }

    /// `evaluateDeviceOwnerPolicy(suppliedContext:,deviceAuthStatus:,localizedReason:)`
    /// when status is cancelled
    func test_evaluateDeviceOwnerPolicy_false_when_status_cancelled() async throws {
        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .cancelled, because: "")

        XCTAssertFalse(result)
    }

    /// `evaluateDeviceOwnerPolicy(suppliedContext:,deviceAuthStatus:,localizedReason:)`
    /// when status is unknown error
    func test_evaluateDeviceOwnerPolicy_false_when_status_unknownError() async throws {
        let result = try await subject.evaluateDeviceOwnerPolicy(laContext, for: .unknownError(""), because: "")

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
