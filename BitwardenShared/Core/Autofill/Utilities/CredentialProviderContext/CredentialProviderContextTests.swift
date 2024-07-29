import AuthenticationServices
import XCTest

@testable import BitwardenShared

class CredentialProviderContextTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:authCompletionRoute` the corresponding route depending on the context mode.
    func test_authCompletionRoute() {
        XCTAssertNil(
            DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false))
                .authCompletionRoute
        )
        XCTAssertEqual(
            DefaultCredentialProviderContext(.autofillVaultList([]))
                .authCompletionRoute,
            AppRoute.vault(.autofillList)
        )
        XCTAssertNil(
            DefaultCredentialProviderContext(
                .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false)
            ).authCompletionRoute
        )
        XCTAssertEqual(
            DefaultCredentialProviderContext(.autofillFido2VaultList([], MockPasskeyCredentialRequestParameters()))
                .authCompletionRoute,
            AppRoute.vault(.autofillList)
        )
        XCTAssertEqual(
            DefaultCredentialProviderContext(.configureAutofill)
                .authCompletionRoute,
            AppRoute.extensionSetup(.extensionActivation(type: .autofillExtension))
        )
        XCTAssertEqual(
            DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
                .authCompletionRoute,
            AppRoute.vault(.autofillList)
        )
    }

    /// `getter:configuring` returns `true` if configuring, `false` otherwise.
    func test_configuring() {
        XCTAssertTrue(
            DefaultCredentialProviderContext(.configureAutofill)
                .configuring
        )
        XCTAssertFalse(
            DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: false))
                .configuring
        )
        XCTAssertFalse(
            DefaultCredentialProviderContext(.autofillVaultList([]))
                .configuring
        )
        XCTAssertFalse(
            DefaultCredentialProviderContext(
                .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false)
            ).configuring
        )
        XCTAssertFalse(
            DefaultCredentialProviderContext(.autofillFido2VaultList([], MockPasskeyCredentialRequestParameters()))
                .configuring
        )
        XCTAssertFalse(
            DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
                .configuring
        )
    }

    /// `getter:extensionMode` returns the proper mode alike the one initialized in the context.
    func test_extensionMode() {
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
            .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false)
        )
        if case .autofillFido2Credential = context4.extensionMode {
            XCTAssert(true)
        } else {
            XCTFail("ExtensionMode doesn't match")
        }

        let context5 = DefaultCredentialProviderContext(
            .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters())
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
                .passwordCredentialIdentity
        )
        XCTAssertNil(
            DefaultCredentialProviderContext(
                .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false)
            ).passwordCredentialIdentity
        )
        XCTAssertNil(
            DefaultCredentialProviderContext(.autofillFido2VaultList([], MockPasskeyCredentialRequestParameters()))
                .passwordCredentialIdentity
        )
        XCTAssertNil(
            DefaultCredentialProviderContext(.configureAutofill)
                .passwordCredentialIdentity
        )
        XCTAssertNil(
            DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
                .passwordCredentialIdentity
        )
    }

    /// `getter:flowFailedBecauseUserInteractionRequired` returns `false` as default.
    func test_flowFailedBecauseUserInteractionRequired_default() {
        XCTAssertFalse(
            DefaultCredentialProviderContext(.autofillCredential(.fixture(), userInteraction: true))
                .flowFailedBecauseUserInteractionRequired
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
            .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: true)
        )
        XCTAssertTrue(subject2True.flowWithUserInteraction)

        let subject2False = DefaultCredentialProviderContext(
            .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false)
        )
        XCTAssertFalse(subject2False.flowWithUserInteraction)

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
            .autofillFido2VaultList(expectedIdentifiers, MockPasskeyCredentialRequestParameters())
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
            .autofillFido2Credential(MockPasskeyCredentialRequest(), userInteraction: false)
        )
        XCTAssertEqual(subject2.serviceIdentifiers, expectedIdentifiers)

        let subject3 = DefaultCredentialProviderContext(.configureAutofill)
        XCTAssertEqual(subject3.serviceIdentifiers, expectedIdentifiers)

        let subject4 = DefaultCredentialProviderContext(.registerFido2Credential(MockPasskeyCredentialRequest()))
        XCTAssertEqual(subject4.serviceIdentifiers, expectedIdentifiers)
    }
}

class MockPasskeyCredentialRequest: PasskeyCredentialRequest {}
