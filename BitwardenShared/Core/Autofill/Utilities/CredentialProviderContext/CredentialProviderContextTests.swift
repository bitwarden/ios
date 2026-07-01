import AuthenticationServices
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

struct CredentialProviderContextTests { // swiftlint:disable:this type_body_length
    // MARK: Tests

    /// `authCompletionRoute` returns the corresponding route depending on the context mode.
    @Test
    func authCompletionRoute() {
        #expect(
            DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false))
                .authCompletionRoute == nil,
        )
        #expect(
            DefaultCredentialProviderContext(.autofillVaultList([]))
                .authCompletionRoute == AppRoute.vault(.autofillList),
        )
        #expect(
            DefaultCredentialProviderContext(
                .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
            ).authCompletionRoute == nil,
        )
        #expect(
            DefaultCredentialProviderContext(.autofillFido2VaultList([], MockPasskeyCredentialRequestParameters()))
                .authCompletionRoute == AppRoute.vault(.autofillList),
        )
        #expect(
            DefaultCredentialProviderContext(
                .autofillOTPCredential(MockOneTimeCodeCredentialIdentity(), userInteraction: false),
            ).authCompletionRoute == nil,
        )
        #expect(
            DefaultCredentialProviderContext(.autofillText).authCompletionRoute == AppRoute.vault(.autofillList),
        )
        #expect(
            DefaultCredentialProviderContext(.configureAutofill)
                .authCompletionRoute == AppRoute.extensionSetup(.extensionActivation(type: .autofillExtension)),
        )
        #expect(
            DefaultCredentialProviderContext(
                .generatePasswordCredential(MockGeneratePasswordRequest(), userInteraction: false),
            ).authCompletionRoute == nil,
        )
        #expect(
            DefaultCredentialProviderContext(
                .generatePasswordCredential(MockGeneratePasswordRequest(), userInteraction: true),
            ).authCompletionRoute == AppRoute.vault(.generatePassword),
        )
        #expect(
            DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
                .authCompletionRoute == AppRoute.vault(.autofillList),
        )
    }

    /// `authCompletionRoute` returns nil for save password credential when proxy cannot be cast.
    @Test
    func authCompletionRoute_savePasswordCredential() {
        #expect(
            DefaultCredentialProviderContext(.savePasswordCredential(MockSavePasswordRequest(), userInteraction: true))
                .authCompletionRoute == nil,
        )
        #expect(
            DefaultCredentialProviderContext(.savePasswordCredential(MockSavePasswordRequest(), userInteraction: false))
                .authCompletionRoute == nil,
        )
    }

    /// `authCompletionRoute` returns the add item route for a save password request
    /// with user interaction on iOS 26.2+.
    @Test
    @available(iOS 26.2, *)
    func authCompletionRoute_savePasswordCredential_iOS26() {
        let credential = ASPasswordCredential(user: "user@example.com", password: "p@ssw0rd")
        let serviceIdentifier = ASCredentialServiceIdentifier(
            identifier: "https://example.com",
            type: .URL,
        )
        let request = ASSavePasswordRequest(
            serviceIdentifier: serviceIdentifier,
            credential: credential,
            title: "Example",
            sessionID: "session-1",
            event: .userInitiated,
        )
        #expect(
            DefaultCredentialProviderContext(.savePasswordCredential(request, userInteraction: true))
                .authCompletionRoute == AppRoute.vault(.addItem(
                    group: .login,
                    newCipherOptions: NewCipherOptions(
                        name: "Example",
                        password: "p@ssw0rd",
                        uri: "https://example.com",
                        username: "user@example.com",
                    ),
                    type: .login,
                )),
        )
    }

    /// `configuring` returns `true` if configuring, `false` otherwise.
    @Test
    func configuring() {
        #expect(DefaultCredentialProviderContext(.configureAutofill).configuring)
        #expect(!DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false)).configuring)
        #expect(!DefaultCredentialProviderContext(.autofillVaultList([])).configuring)
        #expect(
            !DefaultCredentialProviderContext(
                .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
            ).configuring,
        )
        #expect(
            !DefaultCredentialProviderContext(
                .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters()),
            ).configuring,
        )
        #expect(!DefaultCredentialProviderContext(.autofillText).configuring)
        #expect(
            !DefaultCredentialProviderContext(
                .autofillOTPCredential(MockOneTimeCodeCredentialIdentity(), userInteraction: false),
            ).configuring,
        )
        #expect(
            !DefaultCredentialProviderContext(
                .generatePasswordCredential(MockGeneratePasswordRequest(), userInteraction: false),
            ).configuring,
        )
        #expect(
            !DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest())).configuring,
        )
        #expect(
            !DefaultCredentialProviderContext(.savePasswordCredential(MockSavePasswordRequest(), userInteraction: true))
                .configuring,
        )
    }

    /// `extensionMode` returns the proper mode matching the one used to initialize the context.
    @Test
    func extensionMode() {
        let context1 = DefaultCredentialProviderContext(.configureAutofill)
        if case .configureAutofill = context1.extensionMode {} else { Issue.record("ExtensionMode doesn't match") }

        let context2 = DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false))
        if case .autofillCredential = context2.extensionMode {} else { Issue.record("ExtensionMode doesn't match") }

        let context3 = DefaultCredentialProviderContext(.autofillVaultList([]))
        if case .autofillVaultList = context3.extensionMode {} else { Issue.record("ExtensionMode doesn't match") }

        let context4 = DefaultCredentialProviderContext(
            .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
        )
        if case .autofillFido2Credential = context4.extensionMode {} else {
            Issue.record("ExtensionMode doesn't match")
        }

        let context5 = DefaultCredentialProviderContext(
            .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters()),
        )
        if case .autofillFido2VaultList = context5.extensionMode {} else { Issue.record("ExtensionMode doesn't match") }

        let context6 = DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
        if case .registerFido2Credential = context6.extensionMode {} else {
            Issue.record("ExtensionMode doesn't match")
        }

        let context7 = DefaultCredentialProviderContext(
            .autofillOTPCredential(MockOneTimeCodeCredentialIdentity(), userInteraction: false),
        )
        if case .autofillOTPCredential = context7.extensionMode {} else { Issue.record("ExtensionMode doesn't match") }

        let context8 = DefaultCredentialProviderContext(.autofillText)
        if case .autofillText = context8.extensionMode {} else { Issue.record("ExtensionMode doesn't match") }

        let context9 = DefaultCredentialProviderContext(
            .savePasswordCredential(MockSavePasswordRequest(), userInteraction: true),
        )
        if case .savePasswordCredential = context9.extensionMode {} else { Issue.record("ExtensionMode doesn't match") }
    }

    /// `passwordCredentialIdentity` returns the identity of the `autofillCredential` mode.
    @Test
    func passwordCredentialIdentity_autofillCredential() {
        let expectedIdentity = ASPasswordCredentialIdentity.fixture()
        let subject = DefaultCredentialProviderContext(.autofillCredential(expectedIdentity, userInteraction: false))
        #expect(subject.passwordCredentialIdentity == expectedIdentity)
    }

    /// `passwordCredentialIdentity` returns `nil` when mode is not `autofillCredential`.
    @Test
    func passwordCredentialIdentity_nil() {
        #expect(
            DefaultCredentialProviderContext(.autofillVaultList([])).passwordCredentialIdentity == nil,
        )
        #expect(
            DefaultCredentialProviderContext(
                .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
            ).passwordCredentialIdentity == nil,
        )
        #expect(
            DefaultCredentialProviderContext(
                .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters()),
            ).passwordCredentialIdentity == nil,
        )
        #expect(DefaultCredentialProviderContext(.autofillText).passwordCredentialIdentity == nil)
        #expect(DefaultCredentialProviderContext(.configureAutofill).passwordCredentialIdentity == nil)
        #expect(
            DefaultCredentialProviderContext(
                .registerFido2Credential(MockPasskeyCredentialRequest()),
            ).passwordCredentialIdentity == nil,
        )
        #expect(
            DefaultCredentialProviderContext(.savePasswordCredential(MockSavePasswordRequest(), userInteraction: true))
                .passwordCredentialIdentity == nil,
        )
    }

    /// `flowFailedBecauseUserInteractionRequired` returns `false` as the default value.
    @Test
    func flowFailedBecauseUserInteractionRequired_default() {
        #expect(
            !DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: true))
                .flowFailedBecauseUserInteractionRequired,
        )
    }

    /// `flowWithUserInteraction` returns `true` if the flow has user interaction, `false` otherwise.
    @Test
    func flowWithUserInteraction() {
        #expect(DefaultCredentialProviderContext(.autofillVaultList([])).flowWithUserInteraction)

        #expect(
            DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: true))
                .flowWithUserInteraction,
        )
        #expect(
            !DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false))
                .flowWithUserInteraction,
        )

        #expect(
            DefaultCredentialProviderContext(
                .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: true),
            ).flowWithUserInteraction,
        )
        #expect(
            !DefaultCredentialProviderContext(
                .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
            ).flowWithUserInteraction,
        )

        #expect(
            DefaultCredentialProviderContext(
                .autofillOTPCredential(MockOneTimeCodeCredentialIdentity(), userInteraction: true),
            ).flowWithUserInteraction,
        )
        #expect(
            !DefaultCredentialProviderContext(
                .autofillOTPCredential(MockOneTimeCodeCredentialIdentity(), userInteraction: false),
            ).flowWithUserInteraction,
        )

        #expect(DefaultCredentialProviderContext(.autofillText).flowWithUserInteraction)
        #expect(DefaultCredentialProviderContext(.configureAutofill).flowWithUserInteraction)
        #expect(
            DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
                .flowWithUserInteraction,
        )

        #expect(
            !DefaultCredentialProviderContext(
                .generatePasswordCredential(MockGeneratePasswordRequest(), userInteraction: false),
            ).flowWithUserInteraction,
        )
        #expect(
            DefaultCredentialProviderContext(
                .generatePasswordCredential(MockGeneratePasswordRequest(), userInteraction: true),
            ).flowWithUserInteraction,
        )
        #expect(
            DefaultCredentialProviderContext(
                .savePasswordCredential(MockSavePasswordRequest(), userInteraction: true),
            ).flowWithUserInteraction,
        )
        #expect(
            !DefaultCredentialProviderContext(
                .savePasswordCredential(MockSavePasswordRequest(), userInteraction: false),
            ).flowWithUserInteraction,
        )
    }

    /// `serviceIdentifiers` returns the identifiers of the `autofillVaultList` mode.
    @Test
    func serviceIdentifiers_autofillVaultList() {
        let expectedIdentifiers = [
            ASCredentialServiceIdentifier.fixture(),
            ASCredentialServiceIdentifier.fixture(),
        ]
        let subject = DefaultCredentialProviderContext(.autofillVaultList(expectedIdentifiers))
        #expect(subject.serviceIdentifiers == expectedIdentifiers)
    }

    /// `serviceIdentifiers` returns the identifiers of the `autofillFido2VaultList` mode.
    @Test
    func serviceIdentifiers_autofillFido2VaultList() {
        let expectedIdentifiers = [
            ASCredentialServiceIdentifier.fixture(),
            ASCredentialServiceIdentifier.fixture(),
            ASCredentialServiceIdentifier.fixture(),
        ]
        let subject = DefaultCredentialProviderContext(
            .autofillFido2VaultList(expectedIdentifiers, MockPasskeyCredentialRequestParameters()),
        )
        #expect(subject.serviceIdentifiers == expectedIdentifiers)
    }

    /// `serviceIdentifiers` returns empty identifiers when mode is neither
    /// `autofillVaultList` nor `autofillFido2VaultList`.
    @Test
    func serviceIdentifiers_empty() {
        let expectedIdentifiers: [ASCredentialServiceIdentifier] = []

        let subject1 = DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false))
        #expect(subject1.serviceIdentifiers == expectedIdentifiers)

        let subject2 = DefaultCredentialProviderContext(
            .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
        )
        #expect(subject2.serviceIdentifiers == expectedIdentifiers)

        let subject3 = DefaultCredentialProviderContext(.configureAutofill)
        #expect(subject3.serviceIdentifiers == expectedIdentifiers)

        let subject4 = DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
        #expect(subject4.serviceIdentifiers == expectedIdentifiers)

        let subject5 = DefaultCredentialProviderContext(
            .autofillOTPCredential(MockOneTimeCodeCredentialIdentity(), userInteraction: false),
        )
        #expect(subject5.serviceIdentifiers == expectedIdentifiers)

        let subject6 = DefaultCredentialProviderContext(.autofillText)
        #expect(subject6.serviceIdentifiers == expectedIdentifiers)

        let subject7 = DefaultCredentialProviderContext(
            .savePasswordCredential(MockSavePasswordRequest(), userInteraction: true),
        )
        #expect(subject7.serviceIdentifiers == expectedIdentifiers)
    }

    /// `uri` resolves a single service identifier to a URI, normalizing domain-type identifiers
    /// with an HTTPS prefix while preserving URL-type identifiers as-is.
    @Test(arguments: zip(
        [
            ("example.com", ASCredentialServiceIdentifier.IdentifierType.domain),
            ("https://example.com/path", ASCredentialServiceIdentifier.IdentifierType.URL),
        ],
        ["https://example.com", "https://example.com/path"],
    ))
    func uri_serviceIdentifier(
        identifierAndType: (String, ASCredentialServiceIdentifier.IdentifierType),
        expectedURI: String,
    ) {
        let (identifier, identifierType) = identifierAndType
        let serviceIdentifier = ASCredentialServiceIdentifier.fixture(
            identifier: identifier,
            type: identifierType,
        )
        let subject = DefaultCredentialProviderContext(.autofillVaultList([serviceIdentifier]))
        #expect(subject.uri == expectedURI)
    }

    /// `uri` returns the first service identifier's URI when multiple identifiers exist.
    @Test
    func uri_multipleServiceIdentifiers() {
        let identifiers = [
            ASCredentialServiceIdentifier.fixture(identifier: "first.com", type: .domain),
            ASCredentialServiceIdentifier.fixture(identifier: "second.com", type: .domain),
            ASCredentialServiceIdentifier.fixture(identifier: "third.com", type: .domain),
        ]
        let subject = DefaultCredentialProviderContext(.autofillVaultList(identifiers))
        #expect(subject.uri == "https://first.com")
    }

    /// `uri` resolves the relying party identifier for `autofillFido2VaultList` when service identifiers
    /// are empty: adds an HTTPS prefix for bare domains, preserves an existing HTTPS scheme,
    /// and returns `nil` for an empty identifier.
    @Test(arguments: zip(
        ["passkey.example.com", "https://passkey.example.com", ""],
        ["https://passkey.example.com", "https://passkey.example.com", nil] as [String?],
    ))
    func uri_autofillFido2VaultList_emptyServiceIdentifiers(
        relyingParty: String,
        expectedURI: String?,
    ) {
        let parameters = MockPasskeyCredentialRequestParameters(relyingPartyIdentifier: relyingParty)
        let subject = DefaultCredentialProviderContext(.autofillFido2VaultList([], parameters))
        #expect(subject.uri == expectedURI)
    }

    /// `uri` returns the service identifier URI when available for `autofillFido2VaultList`,
    /// ignoring the relying party identifier.
    @Test
    func uri_autofillFido2VaultList_withServiceIdentifiers() {
        let serviceIdentifier = ASCredentialServiceIdentifier.fixture(
            identifier: "actual.example.com",
            type: .domain,
        )
        let parameters = MockPasskeyCredentialRequestParameters(relyingPartyIdentifier: "fallback.example.com")
        let subject = DefaultCredentialProviderContext(.autofillFido2VaultList([serviceIdentifier], parameters))
        #expect(subject.uri == "https://actual.example.com")
    }

    /// `uri` returns `nil` when there are no service identifiers and the mode is not `autofillFido2VaultList`.
    @Test
    func uri_nil() {
        let subject1 = DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false))
        #expect(subject1.uri == nil)

        let subject2 = DefaultCredentialProviderContext(
            .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
        )
        #expect(subject2.uri == nil)

        let subject3 = DefaultCredentialProviderContext(.configureAutofill)
        #expect(subject3.uri == nil)

        let subject4 = DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
        #expect(subject4.uri == nil)

        let subject5 = DefaultCredentialProviderContext(
            .autofillOTPCredential(MockOneTimeCodeCredentialIdentity(), userInteraction: false),
        )
        #expect(subject5.uri == nil)

        let subject6 = DefaultCredentialProviderContext(.autofillText)
        #expect(subject6.uri == nil)

        let subject7 = DefaultCredentialProviderContext(
            .savePasswordCredential(MockSavePasswordRequest(), userInteraction: false),
        )
        #expect(subject7.uri == nil)
    }

    /// `uri` returns `nil` when service identifiers are empty for `autofillVaultList`.
    @Test
    func uri_autofillVaultList_empty() {
        let subject = DefaultCredentialProviderContext(.autofillVaultList([]))
        #expect(subject.uri == nil)
    }
}

class MockPasskeyCredentialRequest: PasskeyCredentialRequest {}

class MockOneTimeCodeCredentialIdentity: OneTimeCodeCredentialIdentityProxy {}

class MockGeneratePasswordRequest: GeneratePasswordRequestProxy {}

class MockSavePasswordRequest: SavePasswordRequestProxy {}
