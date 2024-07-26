// swiftlint:disable:this file_name

import AuthenticationServices
import BitwardenSdk
import XCTest

@testable import BitwardenShared

/// Tests for `VaultAutofillListProcessor` Fido2 flows which require iOS 17
/// and another setup given that the `appExtensionDelegate` is different.
@available(iOS 17.0, *)
class VaultAutofillListProcessorFido2Tests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appExtensionDelegate: MockFido2AppExtensionDelegate!
    var authRepository: MockAuthRepository!
    var autofillCredentialService: MockAutofillCredentialService!
    var clientService: MockClientService!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var fido2CredentialStore: MockFido2CredentialStore!
    var fido2UserInterfaceHelper: MockFido2UserInterfaceHelper!
    var subject: VaultAutofillListProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockFido2AppExtensionDelegate()
        authRepository = MockAuthRepository()
        autofillCredentialService = MockAutofillCredentialService()
        clientService = MockClientService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        fido2CredentialStore = MockFido2CredentialStore()
        fido2UserInterfaceHelper = MockFido2UserInterfaceHelper()
        vaultRepository = MockVaultRepository()

        subject = VaultAutofillListProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                autofillCredentialService: autofillCredentialService,
                clientService: clientService,
                errorReporter: errorReporter,
                fido2CredentialStore: fido2CredentialStore,
                fido2UserInterfaceHelper: fido2UserInterfaceHelper,
                vaultRepository: vaultRepository
            ),
            state: VaultAutofillListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        appExtensionDelegate = nil
        authRepository = nil
        autofillCredentialService = nil
        clientService = nil
        coordinator = nil
        errorReporter = nil
        fido2CredentialStore = nil
        fido2UserInterfaceHelper = nil
        subject = nil
        vaultRepository = nil
    }

    /// `getter:isAutofillingFromList` returns `true` when delegate is autofilling from list.
    func test_isAutofillingFromList_true() async throws {
        appExtensionDelegate.extensionMode = .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters())
        XCTAssertTrue(subject.isAutofillingFromList)
    }

    /// `getter:isAutofillingFromList` returns `false` when delegate is not autofilling from list.
    func test_isAutofillingFromList_false() async throws {
        appExtensionDelegate.extensionMode = .configureAutofill
        XCTAssertFalse(subject.isAutofillingFromList)
    }

    /// `onNeedsUserInteraction()` doesn't throw.
    func test_onNeedsUserInteraction() async throws {
        await assertAsyncDoesNotThrow {
            try await subject.onNeedsUserInteraction()
        }
    }

    /// `receive(_:)` with `.addTapped` navigates to the add item view
    /// with th proper `NewCipherOptions` configuration for Fido2 creation.
    func test_receive_addTapped() throws {
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(userName: "username", rpName: "rpName")
        fido2UserInterfaceHelper.fido2CredentialNewView = fido2CredentialNewView

        let expectedNewCipherOptions = NewCipherOptions(
            name: fido2CredentialNewView.rpName,
            uri: fido2CredentialNewView.rpId,
            username: fido2CredentialNewView.userName
        )

        subject.receive(.addTapped)

        XCTAssertEqual(
            coordinator.routes.last,
            .addItem(allowTypeSelection: false, group: .login, newCipherOptions: expectedNewCipherOptions)
        )
    }

    /// `vaultItemTapped(_:)` with Fido2 credential signals the `Fido2UserInterfaceHelper`
    /// that a cipher has been picked.
    @available(iOSApplicationExtension 17.0, *)
    func test_perform_vaultItemTapped_fido2PickedForCreation() async {
        let expectedResult = CipherView.fixture()
        let vaultListItem = VaultListItem(
            cipherView: expectedResult,
            fido2CredentialAutofillView: .fixture()
        )!
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())

        await subject.perform(.vaultItemTapped(vaultListItem))

        fido2UserInterfaceHelper.pickedCredentialForCreationMocker.assertUnwrapping { result in
            guard case let .success(pickedResult) = result,
                  pickedResult.cipher.cipher.id == expectedResult.id else {
                return false
            }
            return true
        }
    }

    /// `vaultItemTapped(_:)` with Fido2 credential doesn't call the `Fido2UserInterfaceHelper`
    /// that a cipher has been picked for creation when there is no creation request.
    @available(iOSApplicationExtension 17.0, *)
    func test_perform_vaultItemTapped_fido2PickedWhenNotInCreation() async {
        let vaultListItem = VaultListItem(
            cipherView: CipherView.fixture(),
            fido2CredentialAutofillView: .fixture()
        )!

        await subject.perform(.vaultItemTapped(vaultListItem))

        XCTAssertFalse(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)
    }

    /// `perform(_:)` with `.initFido2` provides Fido2 credential from the `autofillCredentialService` when
    /// is autofilling Fido2 from list completing the assertion successfully.
    func test_perform_initFido2_autofillFido2VaultList() async throws {
        let allowedCredentialId = Data(repeating: 3, count: 32)
        let passkeyParameters = MockPasskeyCredentialRequestParameters(
            allowedCredentials: [allowedCredentialId]
        )
        appExtensionDelegate.extensionMode = .autofillFido2VaultList([], passkeyParameters)

        let expectedResult = ASPasskeyAssertionCredential(
            userHandle: Data(repeating: 1, count: 16),
            relyingParty: passkeyParameters.relyingPartyIdentifier,
            signature: Data(repeating: 1, count: 32),
            clientDataHash: passkeyParameters.clientDataHash,
            authenticatorData: Data(repeating: 1, count: 40),
            credentialID: Data(repeating: 1, count: 32)
        )
        autofillCredentialService.provideFido2CredentialResult = .success(expectedResult)

        await subject.perform(.initFido2)

        try await waitForAsync {
            self.appExtensionDelegate.completeAssertionRequestMocker.called
                || !self.errorReporter.errors.isEmpty
        }

        XCTAssertTrue(errorReporter.errors.isEmpty)

        XCTAssertTrue(subject.state.isAutofillingFido2List)
        XCTAssertEqual(subject.state.emptyViewMessage, Localizations.noItemsToList)

        appExtensionDelegate.completeAssertionRequestMocker.assertUnwrapping { credential in
            credential.userHandle == expectedResult.userHandle
                && credential.relyingParty == passkeyParameters.relyingPartyIdentifier
                && credential.signature == expectedResult.signature
                && credential.clientDataHash == passkeyParameters.clientDataHash
                && credential.authenticatorData == expectedResult.authenticatorData
                && credential.credentialID == expectedResult.credentialID
        }
    }

    /// `perform(_:)` with `.initFido2` provides Fido2 credential from the `autofillCredentialService` when
    /// is autofilling Fido2 from list but it throws.
    func test_perform_initFido2_autofillFido2VaultListThrows() async throws {
        let passkeyParameters = MockPasskeyCredentialRequestParameters()
        appExtensionDelegate.extensionMode = .autofillFido2VaultList([], passkeyParameters)

        autofillCredentialService.provideFido2CredentialResult = .failure(BitwardenTestError.example)

        await subject.perform(.initFido2)

        try await waitForAsync {
            self.appExtensionDelegate.completeAssertionRequestMocker.called
                || !self.errorReporter.errors.isEmpty
        }

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertFalse(appExtensionDelegate.completeAssertionRequestMocker.called)
        fido2UserInterfaceHelper.pickedCredentialForAuthenticationMocker.assertUnwrapping { result in
            guard case let .failure(err) = result,
                  err as? BitwardenTestError == BitwardenTestError.example else {
                return false
            }
            return true
        }

        XCTAssertTrue(subject.state.isAutofillingFido2List)
        XCTAssertEqual(subject.state.emptyViewMessage, Localizations.noItemsToList)
    }

    /// `perform(_:)` with `.initFido2` calls `makeCredential` from the Fido2 authenticator when
    /// there is a create FIdo2 request and a credential identity in there as well and completes the registration
    /// when `makeCredential` ends successfully.
    func test_perform_initFido2_registerFido2Credential() async throws {
        let expectedRequest = ASPasskeyCredentialRequest.fixture()
        guard let expectedCredentialIdentity = expectedRequest.credentialIdentity as? ASPasskeyCredentialIdentity else {
            XCTFail("Credential identity is not ASPasskeyCredentialIdentity.")
            return
        }

        appExtensionDelegate.extensionMode = .registerFido2Credential(expectedRequest)

        let expectedResult = MakeCredentialResult.fixture()
        clientService.mockPlatform.fido2Mock
            .clientFido2AuthenticatorMock
            .makeCredentialMocker
            .withVerification { request in
                request.clientDataHash == expectedRequest.clientDataHash
                    && request.rp.id == expectedCredentialIdentity.relyingPartyIdentifier
                    && request.rp.name == expectedCredentialIdentity.relyingPartyIdentifier
                    && request.user.id == expectedCredentialIdentity.userHandle
                    && request.user.name == expectedCredentialIdentity.userName
                    && request.user.displayName == expectedCredentialIdentity.userName
                    && request.pubKeyCredParams.contains(where: { credParams in
                        credParams.ty == "public-key"
                            && credParams.alg == PublicKeyCredentialParameters.es256Algorithm
                    })
                    && request.excludeList == nil
                    && request.options.rk
                    && request.options.uv == .discouraged
                    && request.extensions == nil
            }
            .withResult(expectedResult)

        await subject.perform(.initFido2)

        try await waitForAsync {
            self.appExtensionDelegate.completeRegistrationRequestMocker.called
                || !self.errorReporter.errors.isEmpty
        }

        XCTAssertTrue(errorReporter.errors.isEmpty)

        XCTAssertTrue(fido2UserInterfaceHelper.fido2UserInterfaceHelperDelegate != nil)
        appExtensionDelegate.completeRegistrationRequestMocker.assertUnwrapping { credential in
            credential.relyingParty == expectedCredentialIdentity.relyingPartyIdentifier
                && credential.clientDataHash == expectedRequest.clientDataHash
                && credential.credentialID == expectedResult.credentialId
                && credential.attestationObject == expectedResult.attestationObject
        }
    }

    /// `perform(_:)` with `.initFido2` calls `makeCredential` from the Fido2 authenticator when
    /// there is a create FIdo2 request and a credential identity in there as well and completes the registration
    /// when `makeCredential` ends successfully.
    func test_perform_initFido2_registerFido2CredentialThrows() async throws {
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())

        clientService.mockPlatform.fido2Mock
            .clientFido2AuthenticatorMock
            .makeCredentialMocker
            .throwing(BitwardenTestError.example)

        await subject.perform(.initFido2)

        try await waitForAsync {
            self.appExtensionDelegate.completeRegistrationRequestMocker.called
                || !self.errorReporter.errors.isEmpty
        }

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertFalse(appExtensionDelegate.completeRegistrationRequestMocker.called)
        fido2UserInterfaceHelper.pickedCredentialForCreationMocker.assertUnwrapping { result in
            guard case let .failure(err) = result,
                  err as? BitwardenTestError == BitwardenTestError.example else {
                return false
            }
            return true
        }
    }

    /// `perform(_:)` with `.initFido2` doesn't call `makeCredential` from the Fido2 authenticator when
    /// there is NO create FIdo2 request.
    func test_perform_initFido2_noRequestForFido2Creation() async throws {
        await subject.perform(.initFido2)

        XCTAssertFalse(clientService.mockPlatform.fido2Mock
            .clientFido2AuthenticatorMock
            .makeCredentialMocker
            .called)

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertFalse(appExtensionDelegate.completeRegistrationRequestMocker.called)
    }

    /// `perform(_:)` with `.search()` performs a cipher search and updates the state with the results
    /// when on autofillFido2VaulltList
    func test_perform_search_onAutofillFido2VaultList() { // swiftlint:disable:this function_body_length
        let passkeyParameters = MockPasskeyCredentialRequestParameters()
        appExtensionDelegate.extensionMode = .autofillFido2VaultList([], passkeyParameters)
        let expectedCredentialId = Data(repeating: 123, count: 16)

        let ciphers: [CipherView] = [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")]
        let expectedSections = [
            VaultListSection(
                id: Localizations.passkeysForX("Bit"),
                items: ciphers.suffix(from: 1).compactMap { cipher in
                    VaultListItem(
                        cipherView: cipher,
                        fido2CredentialAutofillView: .fixture(
                            credentialId: expectedCredentialId,
                            cipherId: cipher.id ?? "",
                            rpId: "myApp.com"
                        )
                    )
                },
                name: Localizations.passkeysForX("Bit")
            ),
            VaultListSection(
                id: Localizations.passwordsForX("Bit"),
                items: ciphers.compactMap { VaultListItem(cipherView: $0) },
                name: Localizations.passwordsForX("Bit")
            ),
        ]
        vaultRepository.searchCipherAutofillSubject.value = expectedSections

        let task = Task {
            await subject.perform(.search("Bit"))
        }

        waitFor(!subject.state.ciphersForSearch.isEmpty)
        task.cancel()

        XCTAssertEqual(
            subject.state.ciphersForSearch[0],
            VaultListSection(
                id: Localizations.passkeysForX("Bit"),
                items: ciphers.suffix(from: 1).compactMap { cipher in
                    VaultListItem(
                        cipherView: cipher,
                        fido2CredentialAutofillView: .fixture(
                            credentialId: expectedCredentialId,
                            cipherId: cipher.id ?? "",
                            rpId: "myApp.com"
                        )
                    )
                },
                name: Localizations.passkeysForX("Bit")
            )
        )
        XCTAssertEqual(
            subject.state.ciphersForSearch[1],
            VaultListSection(
                id: Localizations.passwordsForX("Bit"),
                items: ciphers.compactMap { VaultListItem(cipherView: $0) },
                name: Localizations.passwordsForX("Bit")
            )
        )

        XCTAssertFalse(subject.state.showNoResults)
    }
}
