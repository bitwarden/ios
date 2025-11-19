import AuthenticationServices
import XCTest

@testable import BitwardenShared

class CredentialProviderContextTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Tests

    /// `getter:authCompletionRoute` the corresponding route depending on the context mode.
    func test_authCompletionRoute() {
        XCTAssertNil(
            DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false))
                .authCompletionRoute,
        )
        XCTAssertEqual(
            DefaultCredentialProviderContext(.autofillVaultList([]))
                .authCompletionRoute,
            AppRoute.vault(.autofillList),
        )
        XCTAssertNil(
            DefaultCredentialProviderContext(
                .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
            ).authCompletionRoute,
        )
        XCTAssertEqual(
            DefaultCredentialProviderContext(.autofillFido2VaultList([], MockPasskeyCredentialRequestParameters()))
                .authCompletionRoute,
            AppRoute.vault(.autofillList),
        )
        XCTAssertNil(
            DefaultCredentialProviderContext(
                .autofillOTPCredential(MockOneTimeCodeCredentialIdentity(), userInteraction: false),
            ).authCompletionRoute,
        )
        XCTAssertEqual(
            DefaultCredentialProviderContext(.autofillText).authCompletionRoute,
            AppRoute.vault(.autofillList),
        )
        XCTAssertEqual(
            DefaultCredentialProviderContext(.configureAutofill)
                .authCompletionRoute,
            AppRoute.extensionSetup(.extensionActivation(type: .autofillExtension)),
        )
        XCTAssertEqual(
            DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
                .authCompletionRoute,
            AppRoute.vault(.autofillList),
        )
    }

    /// `getter:configuring` returns `true` if configuring, `false` otherwise.
    func test_configuring() {
        XCTAssertTrue(
            DefaultCredentialProviderContext(.configureAutofill)
                .configuring,
        )
        XCTAssertFalse(
            DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false))
                .configuring,
        )
        XCTAssertFalse(
            DefaultCredentialProviderContext(.autofillVaultList([]))
                .configuring,
        )
        XCTAssertFalse(
            DefaultCredentialProviderContext(
                .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
            ).configuring,
        )
        XCTAssertFalse(
            DefaultCredentialProviderContext(.autofillFido2VaultList([], MockPasskeyCredentialRequestParameters()))
                .configuring,
        )
        XCTAssertFalse(
            DefaultCredentialProviderContext(.autofillText).configuring,
        )
        XCTAssertFalse(
            DefaultCredentialProviderContext(
                .autofillOTPCredential(
                    MockOneTimeCodeCredentialIdentity(),
                    userInteraction: false,
                ),
            ).configuring,
        )
        XCTAssertFalse(
            DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
                .configuring,
        )
    }

    /// `getter:extensionMode` returns the proper mode alike the one initialized in the context.
    func test_extensionMode() { // swiftlint:disable:this function_body_length
        let context1 = DefaultCredentialProviderContext(.configureAutofill)
        if case .configureAutofill = context1.extensionMode {
            XCTAssert(true)
        } else {
            XCTFail("ExtensionMode doesn't match")
        }

        let context2 = DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false))
        if case .autofillCredential = context2.extensionMode {
            XCTAssert(true)
        } else {
            XCTFail("ExtensionMode doesn't match")
        }

        let context3 = DefaultCredentialProviderContext(.autofillVaultList([]))
        if case .autofillVaultList = context3.extensionMode {
            XCTAssert(true)
        } else {
            XCTFail("ExtensionMode doesn't match")
        }

        let context4 = DefaultCredentialProviderContext(
            .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
        )
        if case .autofillFido2Credential = context4.extensionMode {
            XCTAssert(true)
        } else {
            XCTFail("ExtensionMode doesn't match")
        }

        let context5 = DefaultCredentialProviderContext(
            .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters()),
        )
        if case .autofillFido2VaultList = context5.extensionMode {
            XCTAssert(true)
        } else {
            XCTFail("ExtensionMode doesn't match")
        }

        let context6 = DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
        if case .registerFido2Credential = context6.extensionMode {
            XCTAssert(true)
        } else {
            XCTFail("ExtensionMode doesn't match")
        }

        let context7 = DefaultCredentialProviderContext(
            .autofillOTPCredential(
                MockOneTimeCodeCredentialIdentity(),
                userInteraction: false,
            ),
        )
        if case .autofillOTPCredential = context7.extensionMode {
            XCTAssert(true)
        } else {
            XCTFail("ExtensionMode doesn't match")
        }

        let context8 = DefaultCredentialProviderContext(.autofillText)
        if case .autofillText = context8.extensionMode {
            XCTAssert(true)
        } else {
            XCTFail("ExtensionMode doesn't match")
        }
    }

    /// `getter:passwordCredentialIdentity` returns the identity of `autofillCredential` mode.
    func test_passwordCredentialIdentity_autofillCredential() {
        let expectedIdentity = ASPasswordCredentialIdentity.fixture()
        let subject = DefaultCredentialProviderContext(.autofillCredential(expectedIdentity, userInteraction: false))
        XCTAssertEqual(subject.passwordCredentialIdentity, expectedIdentity)
    }

    /// `getter:passwordCredentialIdentity` returns `nil` when mode is not `autofillCredential`.
    func test_passwordCredentialIdentity_nil() {
        XCTAssertNil(
            DefaultCredentialProviderContext(.autofillVaultList([]))
                .passwordCredentialIdentity,
        )
        XCTAssertNil(
            DefaultCredentialProviderContext(
                .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
            ).passwordCredentialIdentity,
        )
        XCTAssertNil(
            DefaultCredentialProviderContext(.autofillFido2VaultList([], MockPasskeyCredentialRequestParameters()))
                .passwordCredentialIdentity,
        )
        XCTAssertNil(
            DefaultCredentialProviderContext(.autofillText)
                .passwordCredentialIdentity,
        )
        XCTAssertNil(
            DefaultCredentialProviderContext(.configureAutofill)
                .passwordCredentialIdentity,
        )
        XCTAssertNil(
            DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
                .passwordCredentialIdentity,
        )
    }

    /// `getter:flowFailedBecauseUserInteractionRequired` returns `false` as default.
    func test_flowFailedBecauseUserInteractionRequired_default() {
        XCTAssertFalse(
            DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: true))
                .flowFailedBecauseUserInteractionRequired,
        )
    }

    /// `getter:flowWithUserInteraction` returns `true` if the flow has user interaction,
    /// `false` otherwise.
    func test_flowWithUserInteraction() {
        let subject0 = DefaultCredentialProviderContext(.autofillVaultList([]))
        XCTAssertTrue(subject0.flowWithUserInteraction)

        let subject1True = DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: true))
        XCTAssertTrue(subject1True.flowWithUserInteraction)

        let subject1False = DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false))
        XCTAssertFalse(subject1False.flowWithUserInteraction)

        let subject2True = DefaultCredentialProviderContext(
            .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: true),
        )
        XCTAssertTrue(subject2True.flowWithUserInteraction)

        let subject2False = DefaultCredentialProviderContext(
            .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
        )
        XCTAssertFalse(subject2False.flowWithUserInteraction)

        let subjectOTPCredentialTrue = DefaultCredentialProviderContext(
            .autofillOTPCredential(MockOneTimeCodeCredentialIdentity(), userInteraction: true),
        )
        XCTAssertTrue(subjectOTPCredentialTrue.flowWithUserInteraction)

        let subjectOTPCredentialFalse = DefaultCredentialProviderContext(
            .autofillOTPCredential(MockOneTimeCodeCredentialIdentity(), userInteraction: false),
        )
        XCTAssertFalse(subjectOTPCredentialFalse.flowWithUserInteraction)

        XCTAssertTrue(DefaultCredentialProviderContext(.autofillText).flowWithUserInteraction)

        let subject3 = DefaultCredentialProviderContext(.configureAutofill)
        XCTAssertTrue(subject3.flowWithUserInteraction)

        let subject4 = DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
        XCTAssertTrue(subject4.flowWithUserInteraction)
    }

    /// `getter:serviceIdentifiers` returns the identifiers of `autofillVaultList`.
    func test_serviceIdentifiers_autofillVaultList() {
        let expectedIdentifiers = [
            ASCredentialServiceIdentifier.fixture(),
            ASCredentialServiceIdentifier.fixture(),
        ]
        let subject = DefaultCredentialProviderContext(.autofillVaultList(expectedIdentifiers))
        XCTAssertEqual(subject.serviceIdentifiers, expectedIdentifiers)
    }

    /// `getter:serviceIdentifiers` returns the identifiers of `autofillFido2VaultList`.
    func test_serviceIdentifiers_autofillFido2VaultList() {
        let expectedIdentifiers = [
            ASCredentialServiceIdentifier.fixture(),
            ASCredentialServiceIdentifier.fixture(),
            ASCredentialServiceIdentifier.fixture(),
        ]
        let subject = DefaultCredentialProviderContext(
            .autofillFido2VaultList(expectedIdentifiers, MockPasskeyCredentialRequestParameters()),
        )
        XCTAssertEqual(subject.serviceIdentifiers, expectedIdentifiers)
    }

    /// `getter:serviceIdentifiers` returns empty identifiers
    /// when mode is neither `autofillVaultList` nor `autofillFido2VaultList`.
    func test_serviceIdentifiers_empty() {
        let expectedIdentifiers: [ASCredentialServiceIdentifier] = []

        let subject1 = DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false))
        XCTAssertEqual(subject1.serviceIdentifiers, expectedIdentifiers)

        let subject2 = DefaultCredentialProviderContext(
            .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
        )
        XCTAssertEqual(subject2.serviceIdentifiers, expectedIdentifiers)

        let subject3 = DefaultCredentialProviderContext(.configureAutofill)
        XCTAssertEqual(subject3.serviceIdentifiers, expectedIdentifiers)

        let subject4 = DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
        XCTAssertEqual(subject4.serviceIdentifiers, expectedIdentifiers)

        let subject5 = DefaultCredentialProviderContext(
            .autofillOTPCredential(
                MockOneTimeCodeCredentialIdentity(),
                userInteraction: false,
            ),
        )
        XCTAssertEqual(subject5.serviceIdentifiers, expectedIdentifiers)

        let subject6 = DefaultCredentialProviderContext(.autofillText)
        XCTAssertEqual(subject6.serviceIdentifiers, expectedIdentifiers)
    }

    /// `getter:uri` returns the URI with https prefix when service identifier is a domain.
    func test_uri_domain() {
        let serviceIdentifier = ASCredentialServiceIdentifier.fixture(
            identifier: "example.com",
            type: .domain,
        )
        let subject = DefaultCredentialProviderContext(.autofillVaultList([serviceIdentifier]))
        XCTAssertEqual(subject.uri, "https://example.com")
    }

    /// `getter:uri` returns the URI as-is when service identifier is a URL.
    func test_uri_url() {
        let serviceIdentifier = ASCredentialServiceIdentifier.fixture(
            identifier: "https://example.com/path",
            type: .URL,
        )
        let subject = DefaultCredentialProviderContext(.autofillVaultList([serviceIdentifier]))
        XCTAssertEqual(subject.uri, "https://example.com/path")
    }

    /// `getter:uri` returns the first service identifier when multiple identifiers exist.
    func test_uri_multipleServiceIdentifiers() {
        let identifiers = [
            ASCredentialServiceIdentifier.fixture(identifier: "first.com", type: .domain),
            ASCredentialServiceIdentifier.fixture(identifier: "second.com", type: .domain),
            ASCredentialServiceIdentifier.fixture(identifier: "third.com", type: .domain),
        ]
        let subject = DefaultCredentialProviderContext(.autofillVaultList(identifiers))
        XCTAssertEqual(subject.uri, "https://first.com")
    }

    /// `getter:uri` returns relying party identifier as fallback for autofillFido2VaultList
    /// when service identifiers are empty, normalized with HTTPS prefix.
    func test_uri_autofillFido2VaultList_relyingPartyFallback() {
        let parameters = MockPasskeyCredentialRequestParameters(relyingPartyIdentifier: "passkey.example.com")
        let subject = DefaultCredentialProviderContext(.autofillFido2VaultList([], parameters))
        XCTAssertEqual(subject.uri, "https://passkey.example.com")
    }

    /// `getter:uri` returns relying party identifier normalized, preserving existing HTTPS scheme.
    func test_uri_autofillFido2VaultList_relyingPartyWithHttpsScheme() {
        let parameters = MockPasskeyCredentialRequestParameters(relyingPartyIdentifier: "https://passkey.example.com")
        let subject = DefaultCredentialProviderContext(.autofillFido2VaultList([], parameters))
        XCTAssertEqual(subject.uri, "https://passkey.example.com")
    }

    /// `getter:uri` returns the service identifier URI when available for autofillFido2VaultList,
    /// ignoring the relying party identifier.
    func test_uri_autofillFido2VaultList_withServiceIdentifiers() {
        let serviceIdentifier = ASCredentialServiceIdentifier.fixture(
            identifier: "actual.example.com",
            type: .domain,
        )
        let parameters = MockPasskeyCredentialRequestParameters(relyingPartyIdentifier: "fallback.example.com")
        let subject = DefaultCredentialProviderContext(.autofillFido2VaultList([serviceIdentifier], parameters))
        XCTAssertEqual(subject.uri, "https://actual.example.com")
    }

    /// `getter:uri` returns nil when autofillFido2VaultList has empty service identifiers
    /// and empty relying party identifier.
    func test_uri_autofillFido2VaultList_emptyRelyingParty() {
        let parameters = MockPasskeyCredentialRequestParameters(relyingPartyIdentifier: "")
        let subject = DefaultCredentialProviderContext(.autofillFido2VaultList([], parameters))
        XCTAssertNil(subject.uri)
    }

    /// `getter:uri` returns nil when no service identifiers and not autofillFido2VaultList mode.
    func test_uri_nil() {
        let subject1 = DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false))
        XCTAssertNil(subject1.uri)

        let subject2 = DefaultCredentialProviderContext(
            .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false),
        )
        XCTAssertNil(subject2.uri)

        let subject3 = DefaultCredentialProviderContext(.configureAutofill)
        XCTAssertNil(subject3.uri)

        let subject4 = DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
        XCTAssertNil(subject4.uri)

        let subject5 = DefaultCredentialProviderContext(
            .autofillOTPCredential(MockOneTimeCodeCredentialIdentity(), userInteraction: false),
        )
        XCTAssertNil(subject5.uri)

        let subject6 = DefaultCredentialProviderContext(.autofillText)
        XCTAssertNil(subject6.uri)
    }

    /// `getter:uri` returns nil when service identifiers are empty for autofillVaultList.
    func test_uri_autofillVaultList_empty() {
        let subject = DefaultCredentialProviderContext(.autofillVaultList([]))
        XCTAssertNil(subject.uri)
    }
}

class MockPasskeyCredentialRequest: PasskeyCredentialRequest {}

class MockOneTimeCodeCredentialIdentity: OneTimeCodeCredentialIdentityProxy {}
