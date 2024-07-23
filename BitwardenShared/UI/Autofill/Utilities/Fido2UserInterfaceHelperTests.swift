import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - Fido2UserInterfaceHelperTests

class Fido2UserInterfaceHelperTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var fido2UserInterfaceHelperDelegate: MockFido2UserInterfaceHelperDelegate!
    var fido2UserVerificationMediator: MockFido2UserVerificationMediator!
    var subject: Fido2UserInterfaceHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        fido2UserInterfaceHelperDelegate = MockFido2UserInterfaceHelperDelegate()
        fido2UserVerificationMediator = MockFido2UserVerificationMediator()
        subject = DefaultFido2UserInterfaceHelper(fido2UserVerificationMediator: fido2UserVerificationMediator)
    }

    override func tearDown() {
        super.tearDown()

        fido2UserInterfaceHelperDelegate = nil
        fido2UserVerificationMediator = nil
        subject = nil
    }

    // MARK: Tests

    /// `checkUser(options:hint:)` with hint `informExcludedCredentialFound` is not possible in iOS so far
    /// as the OS doesn't send excluded credentials.
    func test_checkUser_informExcludedCredentialFoundHint() async throws {
        _ = try await subject.checkUser(
            options: CheckUserOptions(requirePresence: true, requireVerification: .discouraged),
            hint: .informExcludedCredentialFound(.fixture())
        )
        throw XCTSkip(
            "informExcludedCredentialFound should never be invoked given iOS doesn't send excluded credentials"
        )
    }

    /// `checkUser(options:hint:)` with hint `informNoCredentialsFound` is not possible in iOS so far
    /// as the OS won't have Fido2 credenitals in the `ASStore` so the list that will be shown to the user for autofill
    /// will be only for passwords.
    func test_checkUser_informNoCredentialsFound() async throws {
        _ = try await subject.checkUser(
            options: CheckUserOptions(requirePresence: true, requireVerification: .discouraged),
            hint: .informNoCredentialsFound
        )
        throw XCTSkip(
            "informNoCredentialsFound should never be invoked given iOS the view will appear only with passwords"
        )
    }

    /// `checkUser(options:hint:)` throws when mediator throws
    func test_checkUser_requestExistingCredentialHint_throwsBecauseMediator() async throws {
        fido2UserVerificationMediator.checkUserResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.checkUser(
                options: CheckUserOptions(requirePresence: true, requireVerification: .discouraged),
                hint: .requestExistingCredential(.fixture())
            )
        }
    }

    /// `checkUser(options:hint:)` returns present and verified when has been verified
    func test_checkUser_requestExistingCredentialHint_verified() async throws {
        fido2UserVerificationMediator.checkUserResult = .success(
            CheckUserResult(userPresent: true, userVerified: true)
        )
        let result = try await subject.checkUser(
            options: CheckUserOptions(requirePresence: true, requireVerification: .discouraged),
            hint: .requestExistingCredential(.fixture())
        )
        XCTAssertTrue(result.userPresent)
        XCTAssertTrue(result.userVerified)
    }

    /// `checkUser(options:hint:)` returns present and not verified when has not been verified.
    func test_checkUser_requestExistingCredentialHint_notVerified() async throws {
        fido2UserVerificationMediator.checkUserResult = .success(
            CheckUserResult(userPresent: true, userVerified: false)
        )
        let result = try await subject.checkUser(
            options: CheckUserOptions(requirePresence: true, requireVerification: .discouraged),
            hint: .requestExistingCredential(.fixture())
        )
        XCTAssertTrue(result.userPresent)
        XCTAssertFalse(result.userVerified)
    }

    /// `checkUser(userVerificationPreference:credential:shouldThrowEnforcingRequiredVerification:)`
    /// returns present and verified when has been verified.
    func test_checkUser_verified() async throws {
        fido2UserVerificationMediator.checkUserResult = .success(
            CheckUserResult(userPresent: true, userVerified: true)
        )
        let result = try await subject.checkUser(
            userVerificationPreference: .preferred,
            credential: .fixture(),
            shouldThrowEnforcingRequiredVerification: false
        )
        XCTAssertTrue(result.userPresent)
        XCTAssertTrue(result.userVerified)
    }

    /// `checkUser(userVerificationPreference:credential:shouldThrowEnforcingRequiredVerification:)`
    /// returns present but not verified when has not been verified and should not enforce required verification.
    func test_checkUser_notVerifiedWithoutEnforcing() async throws {
        fido2UserVerificationMediator.checkUserResult = .success(
            CheckUserResult(userPresent: true, userVerified: false)
        )
        let result = try await subject.checkUser(
            userVerificationPreference: .preferred,
            credential: .fixture(),
            shouldThrowEnforcingRequiredVerification: false
        )
        XCTAssertTrue(result.userPresent)
        XCTAssertFalse(result.userVerified)
    }

    /// `checkUser(userVerificationPreference:credential:shouldThrowEnforcingRequiredVerification:)`
    /// with discouraged  returns present but not verified when has not been verified
    /// and should enforce required verification.
    func test_checkUser_discouragedNotVerifiedEnforcing() async throws {
        fido2UserVerificationMediator.checkUserResult = .success(
            CheckUserResult(userPresent: true, userVerified: false)
        )
        let result = try await subject.checkUser(
            userVerificationPreference: .discouraged,
            credential: .fixture(),
            shouldThrowEnforcingRequiredVerification: true
        )
        XCTAssertTrue(result.userPresent)
        XCTAssertFalse(result.userVerified)
    }

    /// `checkUser(userVerificationPreference:credential:shouldThrowEnforcingRequiredVerification:)`
    /// with required uv preference throws when has not been verified
    /// and should enforce required verification.
    func test_checkUser_requiredNotVerifiedEnforcingThrows() async throws {
        fido2UserVerificationMediator.checkUserResult = .success(
            CheckUserResult(userPresent: true, userVerified: false)
        )
        await assertAsyncThrows(error: Fido2UserVerificationError.requiredEnforcementFailed) {
            _ = try await subject.checkUser(
                userVerificationPreference: .required,
                credential: .fixture(),
                shouldThrowEnforcingRequiredVerification: true
            )
        }
    }

    /// `checkUser(userVerificationPreference:credential:shouldThrowEnforcingRequiredVerification:)`
    /// with preferred uv preference throws when has not been verified, the verification is enabled
    /// and should enforce required verification.
    func test_checkUser_preferredNotVerifiedEnforcingThrows() async throws {
        fido2UserVerificationMediator.checkUserResult = .success(
            CheckUserResult(userPresent: true, userVerified: false)
        )
        fido2UserVerificationMediator.isPreferredVerificationEnabledResult = true
        await assertAsyncThrows(error: Fido2UserVerificationError.requiredEnforcementFailed) {
            _ = try await subject.checkUser(
                userVerificationPreference: .preferred,
                credential: .fixture(),
                shouldThrowEnforcingRequiredVerification: true
            )
        }
    }

    /// `checkUser(userVerificationPreference:credential:shouldThrowEnforcingRequiredVerification:)`
    /// with preferred uv preference returns present but not verified when has not been verified,
    ///  the verification is not enabled and should enforce required verification.
    func test_checkUser_preferredNotVerifiedEnforcingDoesntThrow() async throws {
        fido2UserVerificationMediator.checkUserResult = .success(
            CheckUserResult(userPresent: true, userVerified: false)
        )
        fido2UserVerificationMediator.isPreferredVerificationEnabledResult = false

        let result = try await subject.checkUser(
            userVerificationPreference: .preferred,
            credential: .fixture(),
            shouldThrowEnforcingRequiredVerification: true
        )
        XCTAssertTrue(result.userPresent)
        XCTAssertFalse(result.userVerified)
    }

    /// `checkUser(userVerificationPreference:credential:shouldThrowEnforcingRequiredVerification:)`
    /// throws when mediator throws.
    func test_checkUser_throwsBecauseMediator() async throws {
        fido2UserVerificationMediator.checkUserResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.checkUser(
                userVerificationPreference: .preferred,
                credential: .fixture(),
                shouldThrowEnforcingRequiredVerification: false
            )
        }
    }

    /// `checkUserAndPickCredentialForCreation(options:newCredential:)` returns picked cipher
    /// after succesfully calling `pickedCredentialForCreation(cipherResult:)`.
    func test_checkUserAndPickCredentialForCreation_returnsPickedCipher() async throws {
        let expectedOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .discouraged
        )
        let expectedFido2NewCredential = Fido2CredentialNewView.fixture()
        let task = Task {
            try await subject.checkUserAndPickCredentialForCreation(
                options: expectedOptions,
                newCredential: expectedFido2NewCredential
            )
        }

        try await waitForAsync {
            self.subject.fido2CreationOptions == expectedOptions
                && self.subject.fido2CredentialNewView == expectedFido2NewCredential
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
        XCTAssertNil(subject.fido2CreationOptions)
        XCTAssertNil(subject.fido2CredentialNewView)
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

    /// `pickCredentialForAuthentication(availableCredentials:)` not autofilling from list succeeds
    /// with first available credential.
    func test_pickCredentialForAuthentication_notAutofillingFromListSucceeds() async throws {
        subject.setupDelegate(fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate)
        fido2UserInterfaceHelperDelegate.isAutofillingFromList = false
        let expectedCipher = CipherView.fixture()

        let result = try await subject.pickCredentialForAuthentication(availableCredentials: [expectedCipher])

        XCTAssertEqual(result.cipher, expectedCipher)
    }

    /// `pickCredentialForAuthentication(availableCredentials:)` autofilling from list succeeds
    /// with picked credential.
    func test_pickCredentialForAuthentication_autofillingFromListSucceeds() async throws {
        subject.setupDelegate(fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate)
        fido2UserInterfaceHelperDelegate.isAutofillingFromList = true
        let expectedAvailableCredentials = [CipherView.fixture(id: "1"), CipherView.fixture(id: "2")]

        let task = Task {
            try await subject.pickCredentialForAuthentication(
                availableCredentials: expectedAvailableCredentials
            )
        }

        try await waitForAsync {
            self.subject.availableCredentialsForAuthentication == expectedAvailableCredentials
        }

        try await waitForAsync {
            (self.subject as? DefaultFido2UserInterfaceHelper)?.credentialForAuthenticationContinuation != nil
        }

        let expectedResult = CipherView.fixture(id: "1")
        subject.pickedCredentialForAuthentication(result: .success(expectedResult))

        let result = try await task.value
        XCTAssertEqual(result.cipher, expectedResult)
        XCTAssertNil(subject.availableCredentialsForAuthentication)
    }

    /// `pickCredentialForAuthentication(availableCredentials:)` autofilling from list throws
    /// when picking credential.
    func test_pickCredentialForAuthentication_autofillingFromListThrowsPickingCredential() async throws {
        subject.setupDelegate(fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate)
        fido2UserInterfaceHelperDelegate.isAutofillingFromList = true

        let task = Task {
            try await subject.pickCredentialForAuthentication(
                availableCredentials: [CipherView.fixture(id: "1"), CipherView.fixture(id: "2")]
            )
        }

        try await waitForAsync {
            (self.subject as? DefaultFido2UserInterfaceHelper)?.credentialForAuthenticationContinuation != nil
        }

        subject.pickedCredentialForAuthentication(result: .failure(BitwardenTestError.example))

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await task.value
        }
    }

    /// `pickCredentialForAuthentication(availableCredentials:)` not autofilling from list throws
    /// invalid operation error when available credentials is different from 1.
    func test_pickCredentialForAuthentication_throwsNotAutofillingFromListNoAvailableCredentials() async throws {
        subject.setupDelegate(fido2UserInterfaceHelperDelegate: fido2UserInterfaceHelperDelegate)
        fido2UserInterfaceHelperDelegate.isAutofillingFromList = false
        await assertAsyncThrows(error: Fido2Error.invalidOperationError) {
            _ = try await subject.pickCredentialForAuthentication(availableCredentials: [])
        }
    }

    /// `pickCredentialForAuthentication(availableCredentials:)` throws when no delegate has been set up.
    func test_pickCredentialForAuthentication_throwsNoDelegateSetup() async throws {
        await assertAsyncThrows(error: Fido2Error.noDelegateSetup) {
            _ = try await subject.pickCredentialForAuthentication(availableCredentials: [])
        }
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
        subject.setupDelegate(fido2UserInterfaceHelperDelegate: MockFido2UserInterfaceHelperDelegate())
        XCTAssertTrue(fido2UserVerificationMediator.setupDelegateCalled)
    }
}
