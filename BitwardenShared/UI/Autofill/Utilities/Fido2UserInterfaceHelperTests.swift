import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - Fido2UserInterfaceHelperTests

class Fido2UserInterfaceHelperTests: BitwardenTestCase {
    // MARK: Properties

    var fido2UserVerificationMediator: MockFido2UserVerificationMediator!
    var subject: Fido2UserInterfaceHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        fido2UserVerificationMediator = MockFido2UserVerificationMediator()
        subject = DefaultFido2UserInterfaceHelper(fido2UserVerificationMediator: fido2UserVerificationMediator)
    }

    override func tearDown() {
        super.tearDown()

        fido2UserVerificationMediator = nil
        subject = nil
    }

    // MARK: Tests

    /// `checkUser(options:hint:)`
    func test_checkUser() async throws {
        //  TODO: PM-8829
        _ = try await subject.checkUser(
            options: CheckUserOptions(requirePresence: true, requireVerification: .discouraged),
            hint: .informNoCredentialsFound
        )
        throw XCTSkip("TODO: PM-8829")
    }

    /// `checkUserAndPickCredentialForCreation(options:newCredential:)` returns picked cipher
    /// after succesfully calling `pickedCredentialForCreation(cipherResult:)`.
    func test_checkUserAndPickCredentialForCreation_returnsPickedCipher() async throws {
        let task = Task {
            try await subject.checkUserAndPickCredentialForCreation(
                options: CheckUserOptions(
                    requirePresence: true,
                    requireVerification: .discouraged
                ),
                newCredential: .fixture()
            )
        }

        try await waitForAsync {
            (self.subject as? DefaultFido2UserInterfaceHelper)?.credentialForCreationContinuation != nil
        }

        let expectedResult = CipherView.fixture()
        subject.pickedCredentialForCreation(result:
            .success(
                CheckUserAndPickCredentialForCreationResult(
                    cipher: CipherViewWrapper(cipher: expectedResult),
                    checkUserResult: CheckUserResult(userPresent: true, userVerified: true)
                )
            )
        )

        let result = try await task.value
        XCTAssertEqual(result.cipher.cipher, expectedResult)
    }

    /// `checkUserAndPickCredentialForCreation(options:newCredential:)` returns error
    /// after error calling `pickedCredentialForCreation(cipherResult:)` with an error.
    func test_checkUserAndPickCredentialForCreation_errors() async throws {
        let task = Task {
            try await subject.checkUserAndPickCredentialForCreation(
                options: CheckUserOptions(
                    requirePresence: true,
                    requireVerification: .discouraged
                ),
                newCredential: .fixture()
            )
        }

        try await waitForAsync {
            (self.subject as? DefaultFido2UserInterfaceHelper)?.credentialForCreationContinuation != nil
        }

        subject.pickedCredentialForCreation(result: .failure(BitwardenTestError.example))

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await task.value
        }
    }

    /// `pickCredentialForAuthentication(availableCredentials:)`
    func test_pickCredentialForAuthentication() async throws {
        //  TODO: PM-8829
        _ = try await subject.pickCredentialForAuthentication(availableCredentials: [])
        throw XCTSkip("TODO: PM-8829")
    }

    /// `isVerificationEnabled()`  returns what the mediator returns.
    func test_isVerificationEnabled() async throws {
        fido2UserVerificationMediator.isPreferredVerificationEnabledResult = true
        let resultTrue = await subject.isVerificationEnabled()
        XCTAssertTrue(resultTrue)

        fido2UserVerificationMediator.isPreferredVerificationEnabledResult = false
        let resultFalse = await subject.isVerificationEnabled()
        XCTAssertFalse(resultFalse)
    }

    /// `setupDelegate(fido2UserVerificationMediatorDelegate:)`  sets up deleagte in inner mediator.
    func test_setupDelegate() async throws {
        subject.setupDelegate(fido2UserVerificationMediatorDelegate: MockFido2UserVerificationMediatorDelegate())
        XCTAssertTrue(fido2UserVerificationMediator.setupDelegateCalled)
    }
}
