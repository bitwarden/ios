import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared

class SafariExtensionRequestProcessorTests: BitwardenTestCase {
    func test_makeResponse_generatePassword_returnsGeneratedPasswordResponse() throws {
        let subject = SafariExtensionRequestProcessor(
            passwordGenerator: { _ in "generated-secret" }
        )

        let response = try XCTUnwrap(subject.makeResponse(for: SafariExtensionRequest(kind: .generatePassword)))

        XCTAssertEqual(response.generatedPassword, "generated-secret")
        XCTAssertEqual(response.submissionAction, .generatePassword)
    }

    func test_makeResponse_changePasswordWithMatchedLogin_returnsUpdatePasswordMessage() async throws {
        let request = SafariExtensionRequest(
            kind: .changePassword,
            oldPassword: "old-secret",
            password: "new-secret",
            urlString: "https://example.com/change-password"
        )
        let subject = SafariExtensionRequestProcessor(
            matchedLoginResolver: MockSafariExtensionMatchedLoginResolver(
                matchedLogin: SafariExtensionMatchedLogin(
                    id: "cipher-1",
                    username: "user@example.com",
                    password: "old-secret",
                    urlString: "https://example.com/login"
                )
            )
        )

        let maybeResponse = await subject.makeResponse(for: request)
        let response = try XCTUnwrap(maybeResponse)

        XCTAssertEqual(response.suggestionAction, .updatePassword)
        XCTAssertEqual(response.submissionAction, .updatePassword)
        XCTAssertEqual(response.userMessage, "Update the password for this Bitwarden login.")
    }

    @MainActor
    func test_liveProcessor_withMockServices_makeResponse_generatePasswordReturnsResponse() async throws {
        let subject = SafariExtensionRequestProcessor.live(services: ServiceContainer.withMocks())

        let maybeResponse = await subject.makeResponse(for: SafariExtensionRequest(kind: .generatePassword))
        let response = try XCTUnwrap(maybeResponse)

        XCTAssertEqual(response.submissionAction, .generatePassword)
        XCTAssertNotNil(response.generatedPassword)
        XCTAssertFalse(response.generatedPassword?.isEmpty ?? true)
    }

    @MainActor
    func test_liveProcessor_withMockServices_makeResponse_generatePassword_usesRequestPasswordOptions() async throws {
        let generatorRepository = MockGeneratorRepository()
        generatorRepository.passwordResult = .success("generated-from-options")
        let subject = SafariExtensionRequestProcessor.live(
            services: ServiceContainer.withMocks(generatorRepository: generatorRepository)
        )
        let request = SafariExtensionRequest(
            kind: .generatePassword,
            passwordOptions: PasswordGenerationOptions(
                allowAmbiguousChar: false,
                capitalize: nil,
                includeNumber: nil,
                length: 20,
                lowercase: true,
                minLowercase: 2,
                minNumber: 3,
                minSpecial: nil,
                minUppercase: nil,
                number: true,
                numWords: nil,
                special: false,
                type: .password,
                uppercase: false,
                wordSeparator: nil,
                overridePasswordType: nil
            )
        )

        let maybeResponse = await subject.makeResponse(for: request)
        let response = try XCTUnwrap(maybeResponse)
        let passwordRequest = try XCTUnwrap(generatorRepository.passwordGeneratorRequest)

        XCTAssertEqual(response.generatedPassword, "generated-from-options")
        XCTAssertEqual(passwordRequest.length, 20)
        XCTAssertEqual(passwordRequest.lowercase, true)
        XCTAssertEqual(passwordRequest.numbers, true)
        XCTAssertEqual(passwordRequest.special, false)
        XCTAssertEqual(passwordRequest.uppercase, false)
        XCTAssertEqual(passwordRequest.avoidAmbiguous, true)
        XCTAssertEqual(passwordRequest.minLowercase, 2)
        XCTAssertEqual(passwordRequest.minNumber, 3)
    }

    @MainActor
    func test_liveProcessor_withMockServices_makeResponse_generatePassword_usesSavedPassphraseOptionsWhenRequestDoesNotProvideAny() async throws {
        let generatorRepository = MockGeneratorRepository()
        generatorRepository.passphraseResult = .success("correct-horse-battery-staple")
        generatorRepository.getPasswordGenerationOptionsResult = .success(
            PasswordGenerationOptions(
                allowAmbiguousChar: nil,
                capitalize: true,
                includeNumber: true,
                length: nil,
                lowercase: nil,
                minLowercase: nil,
                minNumber: nil,
                minSpecial: nil,
                minUppercase: nil,
                number: nil,
                numWords: 4,
                special: nil,
                type: .passphrase,
                uppercase: nil,
                wordSeparator: "-",
                overridePasswordType: nil
            )
        )
        let subject = SafariExtensionRequestProcessor.live(
            services: ServiceContainer.withMocks(generatorRepository: generatorRepository)
        )

        let maybeResponse = await subject.makeResponse(for: SafariExtensionRequest(kind: .generatePassword))
        let response = try XCTUnwrap(maybeResponse)
        let passphraseRequest = try XCTUnwrap(generatorRepository.passphraseGeneratorRequest)

        XCTAssertEqual(response.generatedPassword, "correct-horse-battery-staple")
        XCTAssertEqual(passphraseRequest.numWords, 4)
        XCTAssertEqual(passphraseRequest.wordSeparator, "-")
        XCTAssertEqual(passphraseRequest.capitalize, true)
        XCTAssertEqual(passphraseRequest.includeNumber, true)
    }

    @MainActor
    func test_liveProcessor_withMockServices_makeResponse_generatePassword_whenGeneratorFails_returnsFailureMessageWithoutDummyPassword() async throws {
        struct GeneratePasswordError: Error, Equatable {}

        let generatorRepository = MockGeneratorRepository()
        generatorRepository.passwordResult = .failure(GeneratePasswordError())
        let subject = SafariExtensionRequestProcessor.live(
            services: ServiceContainer.withMocks(generatorRepository: generatorRepository)
        )
        let request = SafariExtensionRequest(
            kind: .generatePassword,
            passwordOptions: PasswordGenerationOptions(type: .password)
        )

        let maybeResponse = await subject.makeResponse(for: request)
        let response = try XCTUnwrap(maybeResponse)

        XCTAssertNil(response.generatedPassword)
        XCTAssertEqual(response.submissionAction, .none)
        XCTAssertEqual(response.userMessage, "Couldn’t generate a password in Bitwarden.")
    }

    func test_makeResponse_setup_returnsSetupMessage() throws {
        let subject = SafariExtensionRequestProcessor()

        let response = try XCTUnwrap(subject.makeResponse(for: SafariExtensionRequest(kind: .setup)))

        XCTAssertEqual(response.userMessage, "Safari Web Extension setup")
        XCTAssertEqual(response.submissionAction, .none)
    }

    func test_makeResponse_saveLogin_returnsSuggestedAction() throws {
        let subject = SafariExtensionRequestProcessor()
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "secret",
            urlString: "https://example.com/login",
            username: "user@example.com"
        )

        let response = try XCTUnwrap(subject.makeResponse(for: request))

        XCTAssertEqual(response.suggestionAction, .saveLogin)
        XCTAssertEqual(response.submissionAction, .saveNewLogin)
        XCTAssertEqual(response.userMessage, "Save this login to Bitwarden.")
    }

    func test_makeResponse_fillWithMatchedLogin_returnsFillScriptResponse() async throws {
        let request = SafariExtensionRequest(
            kind: .fill,
            pageDetails: makePageDetails(),
            urlString: "https://example.com/login"
        )
        let subject = SafariExtensionRequestProcessor(
            matchedLoginResolver: MockSafariExtensionMatchedLoginResolver(
                matchedLogin: SafariExtensionMatchedLogin(
                    id: "cipher-1",
                    username: "user@example.com",
                    password: "secret",
                    urlString: "https://example.com/login"
                )
            )
        )

        let maybeResponse = await subject.makeResponse(for: request)
        let response = try XCTUnwrap(maybeResponse)

        XCTAssertEqual(response.submissionAction, .fill)
        XCTAssertEqual(response.matchedLogin?.id, "cipher-1")
        XCTAssertTrue(response.canFinalizeWithScript)
        XCTAssertEqual(response.userMessage, "Filled user@example.com from Bitwarden.")
    }

    func test_makeResponse_fillWithMatchedLoginWithoutUsername_fallsBackToSiteHost() async throws {
        let request = SafariExtensionRequest(
            kind: .fill,
            pageDetails: makePageDetails(),
            urlString: "https://accounts.example.com/login"
        )
        let subject = SafariExtensionRequestProcessor(
            matchedLoginResolver: MockSafariExtensionMatchedLoginResolver(
                matchedLogin: SafariExtensionMatchedLogin(
                    id: "cipher-2",
                    username: "",
                    password: "secret",
                    urlString: "https://accounts.example.com/login"
                )
            )
        )

        let maybeResponse = await subject.makeResponse(for: request)
        let response = try XCTUnwrap(maybeResponse)

        XCTAssertEqual(response.userMessage, "Filled login for accounts.example.com from Bitwarden.")
    }

    func test_makeResponse_fillWithoutMatchedLogin_returnsNoMatchMessage() async throws {
        let request = SafariExtensionRequest(
            kind: .fill,
            pageDetails: makePageDetails(),
            urlString: "https://example.com/login"
        )
        let subject = SafariExtensionRequestProcessor(
            matchedLoginResolver: MockSafariExtensionMatchedLoginResolver(
                matchedLogin: nil
            )
        )

        let maybeResponse = await subject.makeResponse(for: request)
        let response = try XCTUnwrap(maybeResponse)

        XCTAssertEqual(response.submissionAction, .none)
        XCTAssertEqual(response.userMessage, "No matching Bitwarden login found for this page.")
        XCTAssertFalse(response.canFinalizeWithScript)
    }

    func test_makeResponse_saveLoginWithMatchedLogin_returnsUpdateExistingLoginMessage() async throws {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "new-secret",
            urlString: "https://example.com/login",
            username: "user@example.com"
        )
        let subject = SafariExtensionRequestProcessor(
            matchedLoginResolver: MockSafariExtensionMatchedLoginResolver(
                matchedLogin: SafariExtensionMatchedLogin(
                    id: "cipher-1",
                    username: "user@example.com",
                    password: "old-secret",
                    urlString: "https://example.com/login"
                )
            )
        )

        let maybeResponse = await subject.makeResponse(for: request)
        let response = try XCTUnwrap(maybeResponse)

        XCTAssertEqual(response.submissionAction, .updateExistingLogin)
        XCTAssertEqual(response.userMessage, "Update the existing Bitwarden login with these changes.")
    }

    func test_makeResponse_saveLoginConfirmed_persistsCredentialAndReturnsCompletionMessage() async throws {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            requestContext: SafariExtensionRequestContext(
                trigger: .actionPanelPrimary,
                submissionAction: .saveNewLogin
            ),
            password: "secret",
            urlString: "https://example.com/login",
            username: "user@example.com"
        )
        let credentialStore = MockSafariExtensionCredentialStore()
        let subject = SafariExtensionRequestProcessor(
            credentialStore: credentialStore
        )

        let maybeResponse = await subject.makeResponse(for: request)
        let response = try XCTUnwrap(maybeResponse)

        XCTAssertEqual(credentialStore.savedRequests.count, 1)
        XCTAssertEqual(credentialStore.savedRequests.first?.request.username, "user@example.com")
        XCTAssertEqual(credentialStore.savedRequests.first?.submissionAction, .saveNewLogin)
        XCTAssertEqual(response.submissionAction, .saveNewLogin)
        XCTAssertEqual(response.userMessage, "Saved login to Bitwarden.")
    }

    private func makePageDetails() -> PageDetails {
        PageDetails(
            collectedTimestamp: Date(timeIntervalSince1970: 1_715_000_000),
            documentUUID: "doc-1",
            documentUrl: "https://example.com/login",
            fields: [
                PageDetails.Field(
                    disabled: false,
                    elementNumber: 0,
                    form: "form__0",
                    htmlClass: nil,
                    htmlId: "username",
                    htmlName: "username",
                    labelLeft: nil,
                    labelRight: nil,
                    labelTag: "Username",
                    onepasswordFieldType: nil,
                    opId: "field__0",
                    placeholder: nil,
                    readOnly: false,
                    type: "text",
                    value: nil,
                    viewable: true,
                    visible: true
                ),
                PageDetails.Field(
                    disabled: false,
                    elementNumber: 1,
                    form: "form__0",
                    htmlClass: nil,
                    htmlId: "password",
                    htmlName: "password",
                    labelLeft: nil,
                    labelRight: nil,
                    labelTag: "Password",
                    onepasswordFieldType: nil,
                    opId: "field__1",
                    placeholder: nil,
                    readOnly: false,
                    type: "password",
                    value: nil,
                    viewable: true,
                    visible: true
                )
            ],
            forms: [
                "form__0": PageDetails.Form(
                    htmlAction: "https://example.com/login",
                    htmlId: "login-form",
                    htmlMethod: "post",
                    htmlName: "login",
                    opId: "form__0"
                )
            ],
            tabUrl: "https://example.com/login",
            title: "Example",
            url: "https://example.com/login"
        )
    }
}

private struct MockSafariExtensionMatchedLoginResolver: SafariExtensionMatchedLoginResolving {
    var matchedLogin: SafariExtensionMatchedLogin?

    func resolveMatchedLogin(for request: SafariExtensionRequest) async throws -> SafariExtensionMatchedLogin? {
        matchedLogin
    }
}

private final class MockSafariExtensionCredentialStore: SafariExtensionCredentialStoring {
    var savedRequests: [(request: SafariExtensionRequest, matchedLogin: SafariExtensionMatchedLogin?, submissionAction: SafariExtensionSubmissionAction)] = []

    func saveCredential(
        for request: SafariExtensionRequest,
        matchedLogin: SafariExtensionMatchedLogin?,
        submissionAction: SafariExtensionSubmissionAction
    ) async throws {
        savedRequests.append((request, matchedLogin, submissionAction))
    }
}
