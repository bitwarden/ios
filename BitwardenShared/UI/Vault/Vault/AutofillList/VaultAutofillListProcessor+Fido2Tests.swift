// swiftlint:disable:this file_name

import AuthenticationServices
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

/// Tests for `VaultAutofillListProcessor` Fido2 flows which require iOS 17
/// and another setup given that the `appExtensionDelegate` is different.
@available(iOS 17.0, *)
class VaultAutofillListProcessorFido2Tests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appExtensionDelegate: MockAutofillAppExtensionDelegate!
    var authRepository: MockAuthRepository!
    var autofillCredentialService: MockAutofillCredentialService!
    var clientService: MockClientService!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var fido2CredentialStore: MockFido2CredentialStore!
    var fido2UserInterfaceHelper: MockFido2UserInterfaceHelper!
    var subject: VaultAutofillListProcessor!
    var timeProvider: MockTimeProvider!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAutofillAppExtensionDelegate()
        authRepository = MockAuthRepository()
        autofillCredentialService = MockAutofillCredentialService()
        clientService = MockClientService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        fido2CredentialStore = MockFido2CredentialStore()
        fido2UserInterfaceHelper = MockFido2UserInterfaceHelper()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2024, month: 2, day: 14, hour: 8, minute: 0, second: 0)))
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
                timeProvider: timeProvider,
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
        timeProvider = nil
        vaultRepository = nil
    }

    /// `informExcludedCredentialFound(cipherView:)` updates the state with the excluded credential.
    @MainActor
    func test_informExcludedCredentialFound() async throws {
        let cipher = CipherView.fixture()
        await subject.informExcludedCredentialFound(cipherView: cipher)
        XCTAssertEqual(subject.state.excludedCredentialIdFound, "1")
    }

    /// `getter:isAutofillingFromList` returns `true` when delegate is autofilling from list.
    @MainActor
    func test_isAutofillingFromList_true() async throws {
        appExtensionDelegate.extensionMode = .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters())
        XCTAssertTrue(subject.isAutofillingFromList)
    }

    /// `getter:isAutofillingFromList` returns `false` when delegate is not autofilling from list.
    @MainActor
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

    /// `receive(_:)` with `.addTapped` navigates to the add item view when executed from the toolbar
    /// with the proper `NewCipherOptions` configuration for Fido2 creation.
    @MainActor
    func test_receive_addTapped() throws {
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(userName: "username", rpName: "rpName")
        fido2UserInterfaceHelper.fido2CredentialNewView = fido2CredentialNewView

        let expectedNewCipherOptions = NewCipherOptions(
            name: fido2CredentialNewView.rpName,
            uri: fido2CredentialNewView.rpId,
            username: fido2CredentialNewView.userName
        )

        subject.receive(.addTapped(fromFAB: true))

        XCTAssertEqual(
            coordinator.routes.last,
            .addItem(group: .login, newCipherOptions: expectedNewCipherOptions, type: .login)
        )
    }

    /// `receive(_:)` with `.addTapped` creates a new default cipher with the Fido2 credential
    /// when executed from the empty view and in the create Fido2 credential context.
    @MainActor
    func test_receive_addTapped_fido2CreationEmptyView() throws {
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(userName: "username", rpName: "rpName")
        fido2UserInterfaceHelper.fido2CredentialNewView = fido2CredentialNewView
        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .required
        )

        fido2UserInterfaceHelper.checkUserResult = .success(CheckUserResult(userPresent: true, userVerified: true))

        subject.receive(.addTapped(fromFAB: false))

        waitFor(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)

        fido2UserInterfaceHelper.pickedCredentialForCreationMocker.assertUnwrapping { result in
            guard case let .success(pickedResult) = result,
                  pickedResult.checkUserResult.userVerified,
                  pickedResult.cipher.cipher.id == nil,
                  pickedResult.cipher.cipher.type == .login,
                  pickedResult.cipher.cipher.name == "rpName",
                  pickedResult.cipher.cipher.login?.username == "username",
                  pickedResult.cipher.cipher.login?.uris?.first?.uri == "myApp.com" else {
                return false
            }
            return true
        }
    }

    /// `receive(_:)` with `.addTapped` creates a new default cipher with the Fido2 credential
    /// when executed from the empty view and in the create Fido2 credential context but user not verified.
    @MainActor
    func test_receive_addTapped_fido2CreationEmptyViewUserNotVerified() throws {
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(userName: "username", rpName: "rpName")
        fido2UserInterfaceHelper.fido2CredentialNewView = fido2CredentialNewView
        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .required
        )

        fido2UserInterfaceHelper.checkUserResult = .success(CheckUserResult(userPresent: true, userVerified: false))

        subject.receive(.addTapped(fromFAB: false))

        waitFor(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)

        fido2UserInterfaceHelper.pickedCredentialForCreationMocker.assertUnwrapping { result in
            guard case let .success(pickedResult) = result,
                  !pickedResult.checkUserResult.userVerified,
                  pickedResult.cipher.cipher.id == nil,
                  pickedResult.cipher.cipher.type == .login,
                  pickedResult.cipher.cipher.name == "rpName",
                  pickedResult.cipher.cipher.login?.username == "username",
                  pickedResult.cipher.cipher.login?.uris?.first?.uri == "myApp.com" else {
                return false
            }
            return true
        }
    }

    /// `receive(_:)` with `.addTapped` shows an alert and logs
    /// when executed from the empty view and in the create Fido2 credential context but user verification throws.
    @MainActor
    func test_receive_addTapped_fido2CreationEmptyViewUserVerificationThrows() throws {
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(userName: "username", rpName: "rpName")
        fido2UserInterfaceHelper.fido2CredentialNewView = fido2CredentialNewView
        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .required
        )

        fido2UserInterfaceHelper.checkUserResult = .failure(BitwardenTestError.example)

        subject.receive(.addTapped(fromFAB: false))

        waitFor(!errorReporter.errors.isEmpty)

        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `receive(_:)` with `.addTapped` does nothing when executed from the empty view
    /// and in the create Fido2 credential context but user verification cancelled.
    @MainActor
    func test_receive_addTapped_fido2CreationEmptyViewUserVerificationCancelled() throws {
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(userName: "username", rpName: "rpName")
        fido2UserInterfaceHelper.fido2CredentialNewView = fido2CredentialNewView
        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .required
        )

        fido2UserInterfaceHelper.checkUserResult = .failure(UserVerificationError.cancelled)

        subject.receive(.addTapped(fromFAB: false))

        waitFor(fido2UserInterfaceHelper.checkUserCalled)

        XCTAssertFalse(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)
    }

    /// `receive(_:)` with `.addTapped` shows an alert when executed from the empty view
    /// and in the create Fido2 credential context but without Fido2 options.
    @MainActor
    func test_receive_addTapped_fido2CreationEmptyViewFido2OptionsNull() throws {
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(userName: "username", rpName: "rpName")
        fido2UserInterfaceHelper.fido2CredentialNewView = fido2CredentialNewView

        subject.receive(.addTapped(fromFAB: false))

        waitFor(!coordinator.alertShown.isEmpty)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .defaultAlert(
                title: Localizations.anErrorHasOccurred
            )
        )
    }

    /// `receive(_:)` with `.addTapped` shows an alert when executed from the empty view
    /// and in the create Fido2 credential context but without Fido2 credential new view.
    @MainActor
    func test_receive_addTapped_fido2CreationEmptyViewFido2CredentialNewViewNull() throws {
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .required
        )

        subject.receive(.addTapped(fromFAB: false))

        waitFor(!coordinator.alertShown.isEmpty)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .defaultAlert(
                title: Localizations.anErrorHasOccurred
            )
        )
    }

    /// `perform(_:)` with `.excludedCredentialFoundChaged` updates the state with the excluded credential
    /// vault list section.
    @MainActor
    func test_perform_excludedCredentialFoundChaged() async throws {
        let cipher = CipherView.fixture(login: .fixture(fido2Credentials: [.fixture()]))
        subject.state.excludedCredentialIdFound = cipher.id
        vaultRepository.cipherDetailsSubject.send(cipher)
        vaultRepository.createAutofillListExcludedCredentialSectionResult = .success(
            VaultListSection(
                id: "excludedCredentialsId",
                items: [
                    VaultListItem(
                        cipherListView: .fixture(id: cipher.id),
                        fido2CredentialAutofillView: .fixture()
                    )!,
                ],
                name: "excludedCredentialsId"
            )
        )

        let task = Task {
            await subject.perform(.excludedCredentialFoundChaged)
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !subject.state.vaultListSections.isEmpty
        }

        XCTAssertEqual(subject.state.excludedCredentialIdFound, "1")
        XCTAssertEqual(subject.state.vaultListSections.count, 1)
        let firstSection = try XCTUnwrap(subject.state.vaultListSections.first)
        XCTAssertEqual(firstSection.id, "excludedCredentialsId")
        XCTAssertEqual(firstSection.name, "excludedCredentialsId")
        XCTAssertEqual(firstSection.items.count, 1)
        let firstItem = try XCTUnwrap(firstSection.items.first)
        XCTAssertEqual(firstItem.id, cipher.id)
    }

    /// `perform(_:)` with `.excludedCredentialFoundChaged` updates the state with the excluded credential
    /// vault list section but then sets `excludedCredentialFound` to `nil` in state when cipher
    /// has no Fido2 credentials.
    @MainActor
    func test_perform_excludedCredentialFoundChaged_cipherHasNoFido2Credentials() async throws {
        let cipher = CipherView.fixture(login: .fixture(fido2Credentials: [.fixture()]))
        subject.state.excludedCredentialIdFound = cipher.id
        vaultRepository.cipherDetailsSubject.send(cipher)
        vaultRepository.createAutofillListExcludedCredentialSectionResult = .success(
            VaultListSection(
                id: "excludedCredentialsId",
                items: [
                    VaultListItem(
                        cipherListView: .fixture(id: cipher.id),
                        fido2CredentialAutofillView: .fixture()
                    )!,
                ],
                name: "excludedCredentialsId"
            )
        )

        let task = Task {
            await subject.perform(.excludedCredentialFoundChaged)
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !subject.state.vaultListSections.isEmpty
        }

        XCTAssertEqual(subject.state.excludedCredentialIdFound, "1")
        XCTAssertEqual(subject.state.vaultListSections.count, 1)

        vaultRepository.cipherDetailsSubject.send(
            CipherView.fixture(
                login: .fixture(
                    fido2Credentials: []
                )
            )
        )
        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return subject.state.excludedCredentialIdFound == nil
        }
    }

    /// `perform(_:)` with `.excludedCredentialFoundChaged` throws when getting the excluded credential cipher
    /// from the publisher so it shows an error and cancels the extension flow.
    @MainActor
    func test_perform_excludedCredentialFoundChaged_cipherPublisherThrows() async throws {
        let cipher = CipherView.fixture()
        subject.state.excludedCredentialIdFound = cipher.id
        vaultRepository.cipherDetailsSubject.send(completion: .failure(BitwardenTestError.example))

        let task = Task {
            await subject.perform(.excludedCredentialFoundChaged)
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !coordinator.alertShown.isEmpty
        }

        XCTAssertEqual(subject.state.excludedCredentialIdFound, "1")
        XCTAssertTrue(subject.state.vaultListSections.isEmpty)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.aPasskeyAlreadyExistsForThisApplicationButAnErrorOccurredWhileLoadingIt
            )
        )

        guard let onDismissed = coordinator.alertOnDismissed else {
            XCTFail("Alert does nothing on dismiss when it should.")
            return
        }
        onDismissed()

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
    }

    /// `perform(_:)` with `.excludedCredentialFoundChaged` throws when creating the excluded credential cipher
    /// section so it shows an error and cancels the extension flow.
    @MainActor
    func test_informExcludedCredentialFound_creatingExcludeCredentialSectionThrows() async throws {
        let cipher = CipherView.fixture(login: .fixture(fido2Credentials: [.fixture()]))
        subject.state.excludedCredentialIdFound = cipher.id
        vaultRepository.cipherDetailsSubject.send(cipher)
        vaultRepository.createAutofillListExcludedCredentialSectionResult = .failure(BitwardenTestError.example)

        let task = Task {
            await subject.perform(.excludedCredentialFoundChaged)
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !coordinator.alertShown.isEmpty
        }

        XCTAssertEqual(subject.state.excludedCredentialIdFound, "1")
        XCTAssertTrue(subject.state.vaultListSections.isEmpty)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.aPasskeyAlreadyExistsForThisApplicationButAnErrorOccurredWhileLoadingIt
            )
        )

        guard let onDismissed = coordinator.alertOnDismissed else {
            XCTFail("Alert does nothing on dismiss when it should.")
            return
        }
        onDismissed()

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
    }

    /// `vaultItemTapped(_:)` with Fido2 credential signals the `Fido2UserInterfaceHelper`
    /// that a cipher has been picked for authentication when in `autofillFido2VaultList` mode.
    @available(iOSApplicationExtension 17.0, *)
    @MainActor
    func test_perform_vaultItemTapped_fido2PickedForAuthentication() async {
        appExtensionDelegate.extensionMode = .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters())
        let vaultListItem = VaultListItem(
            cipherListView: .fixture(),
            fido2CredentialAutofillView: .fixture()
        )!
        vaultRepository.fetchCipherResult = .success(.fixture())

        await subject.perform(.vaultItemTapped(vaultListItem))

        fido2UserInterfaceHelper.pickedCredentialForAuthenticationMocker.assertUnwrapping { result in
            guard case let .success(pickedResult) = result,
                  pickedResult.id == vaultListItem.id else {
                return false
            }
            return true
        }
    }

    /// `vaultItemTapped(_:)` with Fido2 credential signals the `Fido2UserInterfaceHelper`
    /// that a cipher has been picked when user confirms overwriting it.
    @available(iOSApplicationExtension 17.0, *)
    @MainActor
    func test_perform_vaultItemTapped_fido2PickedForCreationWithAlreadyFido2Credential() async throws {
        let expectedCipher = Cipher.fixture(
            id: "1",
            login: .fixture(
                fido2Credentials: [.fixture()]
            ),
            type: .login
        )
        let expectedResult = CipherListView(cipher: expectedCipher)
        let vaultListItem = VaultListItem(
            cipherListView: expectedResult,
            fido2CredentialAutofillView: .fixture()
        )!
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        vaultRepository.fetchCipherResult = .success(CipherView(cipher: expectedCipher))

        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .required
        )
        fido2UserInterfaceHelper.checkUserResult = .success(CheckUserResult(userPresent: true, userVerified: true))

        await subject.perform(.vaultItemTapped(vaultListItem))

        waitFor(!coordinator.alertShown.isEmpty)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(
            alert.title,
            Localizations.thisItemAlreadyContainsAPasskeyAreYouSureYouWantToOverwriteTheCurrentPasskey
        )
        try await alert.tapAction(title: Localizations.yes)

        fido2UserInterfaceHelper.pickedCredentialForCreationMocker.assertUnwrapping { result in
            guard case let .success(pickedResult) = result,
                  pickedResult.checkUserResult.userVerified,
                  pickedResult.cipher.cipher.id == expectedResult.id else {
                return false
            }
            return true
        }
    }

    /// `vaultItemTapped(_:)` with Fido2 credential doesn't signal the `Fido2UserInterfaceHelper`
    /// that a cipher has been picked when user denies overwriting it.
    @available(iOSApplicationExtension 17.0, *)
    @MainActor
    func test_perform_vaultItemTapped_fido2PickedForCreationNoOverwrite() async throws {
        let expectedCipher = Cipher.fixture(
            id: "1",
            login: .fixture(
                fido2Credentials: [.fixture()]
            ),
            type: .login
        )
        let expectedResult = CipherListView(cipher: expectedCipher)
        let vaultListItem = VaultListItem(
            cipherListView: expectedResult,
            fido2CredentialAutofillView: .fixture()
        )!
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())

        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .required
        )
        vaultRepository.fetchCipherResult = .success(CipherView(cipher: expectedCipher))

        await subject.perform(.vaultItemTapped(vaultListItem))

        waitFor(!coordinator.alertShown.isEmpty)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.cancel)

        XCTAssertFalse(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)
        XCTAssertFalse(fido2UserInterfaceHelper.checkUserCalled)
    }

    /// `vaultItemTapped(_:)` with Fido2 credential doesn't signal the `Fido2UserInterfaceHelper`
    /// when no Fido2 options are available and shows an error to the user.
    @available(iOSApplicationExtension 17.0, *)
    @MainActor
    func test_perform_vaultItemTapped_fido2PickedForCreationNoFido2Options() async throws {
        let expectedResult = CipherListView.fixture(
            login: .fixture(fido2Credentials: [.fixture()])
        )
        let vaultListItem = VaultListItem(
            cipherListView: expectedResult,
            fido2CredentialAutofillView: .fixture()
        )!
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())

        await subject.perform(.vaultItemTapped(vaultListItem))

        waitFor(!coordinator.alertShown.isEmpty)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .defaultAlert(
                title: Localizations.anErrorHasOccurred
            )
        )
        XCTAssertFalse(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)
        XCTAssertFalse(fido2UserInterfaceHelper.checkUserCalled)
    }

    /// `vaultItemTapped(_:)` with cipher signals the `Fido2UserInterfaceHelper`
    /// that a cipher has been picked when in creating Fido2 credential context and user check was verified.
    @available(iOSApplicationExtension 17.0, *)
    @MainActor
    func test_perform_vaultItemTapped_cipherPickedForFido2Creation() async throws {
        let expectedCipher = Cipher.fixture(
            id: "1",
            login: .fixture(),
            type: .login
        )
        let expectedResult = CipherListView(cipher: expectedCipher)
        let vaultListItem = VaultListItem(
            cipherListView: expectedResult
        )!
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())

        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .required
        )
        fido2UserInterfaceHelper.checkUserResult = .success(CheckUserResult(userPresent: true, userVerified: true))
        vaultRepository.fetchCipherResult = .success(CipherView(cipher: expectedCipher))

        await subject.perform(.vaultItemTapped(vaultListItem))

        waitFor(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)

        fido2UserInterfaceHelper.pickedCredentialForCreationMocker.assertUnwrapping { result in
            guard case let .success(pickedResult) = result,
                  pickedResult.checkUserResult.userVerified,
                  pickedResult.cipher.cipher.id == expectedResult.id else {
                return false
            }
            return true
        }
    }

    /// `vaultItemTapped(_:)` with cipher signals the `Fido2UserInterfaceHelper`
    /// that a cipher has been picked when in creating Fido2 credential context and user check was not verified.
    @available(iOSApplicationExtension 17.0, *)
    @MainActor
    func test_perform_vaultItemTapped_cipherPickedForFido2CreationUserCheckNotVerified() async throws {
        let expectedCipher = Cipher.fixture(
            id: "1",
            login: .fixture(),
            type: .login
        )
        let expectedResult = CipherListView(cipher: expectedCipher)
        let vaultListItem = VaultListItem(
            cipherListView: expectedResult
        )!
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())

        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .required
        )
        fido2UserInterfaceHelper.checkUserResult = .success(CheckUserResult(userPresent: true, userVerified: false))
        vaultRepository.fetchCipherResult = .success(CipherView(cipher: expectedCipher))

        await subject.perform(.vaultItemTapped(vaultListItem))

        waitFor(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)

        fido2UserInterfaceHelper.pickedCredentialForCreationMocker.assertUnwrapping { result in
            guard case let .success(pickedResult) = result,
                  !pickedResult.checkUserResult.userVerified,
                  pickedResult.cipher.cipher.id == expectedResult.id else {
                return false
            }
            return true
        }
    }

    /// `vaultItemTapped(_:)` with cipher shows alert and logs when
    /// a cipher has been picked in creating Fido2 credential context and user check throws.
    @available(iOSApplicationExtension 17.0, *)
    @MainActor
    func test_perform_vaultItemTapped_cipherPickedForFido2CreationUserCheckThrows() async throws {
        let expectedCipher = Cipher.fixture(
            id: "1",
            login: .fixture(),
            type: .login
        )
        let expectedResult = CipherListView(cipher: expectedCipher)
        let vaultListItem = VaultListItem(
            cipherListView: expectedResult
        )!
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())

        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .required
        )
        fido2UserInterfaceHelper.checkUserResult = .failure(BitwardenTestError.example)
        vaultRepository.fetchCipherResult = .success(CipherView(cipher: expectedCipher))

        await subject.perform(.vaultItemTapped(vaultListItem))

        waitFor(!errorReporter.errors.isEmpty)

        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `vaultItemTapped(_:)` with cipher does nothing when
    /// a cipher has been picked in creating Fido2 credential context and user check is cancelled.
    @available(iOSApplicationExtension 17.0, *)
    @MainActor
    func test_perform_vaultItemTapped_cipherPickedForFido2CreationUserCheckCancelled() async throws {
        let expectedCipher = Cipher.fixture(
            id: "1",
            login: .fixture(),
            type: .login
        )
        let expectedResult = CipherListView(cipher: expectedCipher)
        let vaultListItem = VaultListItem(
            cipherListView: expectedResult
        )!
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())

        fido2UserInterfaceHelper.fido2CreationOptions = CheckUserOptions(
            requirePresence: true,
            requireVerification: .required
        )
        fido2UserInterfaceHelper.checkUserResult = .failure(UserVerificationError.cancelled)
        vaultRepository.fetchCipherResult = .success(CipherView(cipher: expectedCipher))

        await subject.perform(.vaultItemTapped(vaultListItem))

        waitFor(fido2UserInterfaceHelper.checkUserCalled)

        XCTAssertFalse(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)
    }

    /// `vaultItemTapped(_:)` with Fido2 credential doesn't call the `Fido2UserInterfaceHelper`
    /// that a cipher has been picked for creation when there is no creation request.
    @available(iOSApplicationExtension 17.0, *)
    @MainActor
    func test_perform_vaultItemTapped_fido2PickedWhenNotInCreation() async {
        let vaultListItem = VaultListItem(
            cipherListView: CipherListView.fixture(),
            fido2CredentialAutofillView: .fixture()
        )!

        await subject.perform(.vaultItemTapped(vaultListItem))

        XCTAssertFalse(fido2UserInterfaceHelper.pickedCredentialForCreationMocker.called)
    }

    /// `perform(_:)` with `.initFido2` provides Fido2 credential from the `autofillCredentialService` when
    /// is autofilling Fido2 from list completing the assertion successfully.
    @MainActor
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
        XCTAssertEqual(subject.state.emptyViewMessage, Localizations.noItemsTap)

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
    @MainActor
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
        XCTAssertEqual(subject.state.emptyViewMessage, Localizations.noItemsTap)
    }

    /// `perform(_:)` with `.initFido2` calls `makeCredential` from the Fido2 authenticator when
    /// there is a create FIdo2 request and a credential identity in there as well and completes the registration
    /// when `makeCredential` ends successfully.
    @MainActor
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
        XCTAssertTrue(subject.state.isCreatingFido2Credential)
        XCTAssertEqual(
            subject.state.emptyViewMessage,
            Localizations.noItemsForUri(expectedCredentialIdentity.relyingPartyIdentifier)
        )
        XCTAssertEqual(subject.state.emptyViewButtonText, Localizations.savePasskeyAsNewLogin)

        XCTAssertTrue(fido2UserInterfaceHelper.fido2UserInterfaceHelperDelegate != nil)
        XCTAssertEqual(fido2UserInterfaceHelper.userVerificationPreferenceSetup, .discouraged)
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
    @MainActor
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
    @MainActor
    func test_perform_initFido2_noRequestForFido2Creation() async throws {
        await subject.perform(.initFido2)

        XCTAssertFalse(clientService.mockPlatform.fido2Mock
            .clientFido2AuthenticatorMock
            .makeCredentialMocker
            .called)

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertFalse(appExtensionDelegate.completeRegistrationRequestMocker.called)
    }

    /// `perform(_:)` with `.initFido2` doesn't call `makeCredential` from the Fido2 authenticator when
    /// there is a create FIdo2 request but an excluded credential has been found.
    @MainActor
    func test_perform_initFido2_registerFido2CredentialExcludedCredential() async throws {
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        subject.state.excludedCredentialIdFound = "1"

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
    @MainActor
    func test_perform_search_onAutofillFido2VaultList() { // swiftlint:disable:this function_body_length
        let passkeyParameters = MockPasskeyCredentialRequestParameters()
        appExtensionDelegate.extensionMode = .autofillFido2VaultList([], passkeyParameters)
        let expectedCredentialId = Data(repeating: 123, count: 16)

        let ciphers: [CipherListView] = [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")]
        let expectedSections = [
            VaultListSection(
                id: Localizations.passkeysForX("Bit"),
                items: ciphers.suffix(from: 1).compactMap { cipher in
                    VaultListItem(
                        cipherListView: cipher,
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
                items: ciphers.compactMap { VaultListItem(cipherListView: $0) },
                name: Localizations.passwordsForX("Bit")
            ),
        ]
        vaultRepository.searchCipherAutofillSubject.value = VaultListData(sections: expectedSections)

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
                        cipherListView: cipher,
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
                items: ciphers.compactMap { VaultListItem(cipherListView: $0) },
                name: Localizations.passwordsForX("Bit")
            )
        )

        XCTAssertFalse(subject.state.showNoResults)
    }

    /// `perform(_:)` with `.streamAutofillItems` streams the list of autofill ciphers when creating Fido2 credential.
    @MainActor
    func test_perform_streamAutofillItems_creatingFido2Credential() {
        let rpId = "myApp.com"
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture(
            credentialIdentity: .fixture(relyingPartyIdentifier: rpId)
        ))
        let ciphers: [CipherListView] = [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")]
        let expectedSection = VaultListSection(
            id: "",
            items: ciphers.compactMap { VaultListItem(cipherListView: $0) },
            name: ""
        )
        vaultRepository.ciphersAutofillSubject.value = VaultListData(sections: [expectedSection])

        let task = Task {
            await subject.perform(.streamAutofillItems)
        }

        waitFor(!subject.state.vaultListSections.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.vaultListSections, [expectedSection])
        XCTAssertEqual(vaultRepository.ciphersAutofillPublisherUriCalled, "https://\(rpId)")
    }

    /// `perform(_:)` with `.streamAutofillItems` doesn't update the sections when
    /// excluded credentials have been found.
    @MainActor
    func test_perform_streamAutofillItems_excludedCredentials() {
        let rpId = "myApp.com"
        subject.state.excludedCredentialIdFound = "1"
        appExtensionDelegate.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture(
            credentialIdentity: .fixture(relyingPartyIdentifier: rpId)
        ))
        let ciphers: [CipherListView] = [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")]
        let section = VaultListSection(
            id: "",
            items: ciphers.compactMap { VaultListItem(cipherListView: $0) },
            name: ""
        )
        vaultRepository.ciphersAutofillSubject.value = VaultListData(sections: [section])

        let task = Task {
            await subject.perform(.streamAutofillItems)
        }

        waitFor(vaultRepository.ciphersAutofillPublisherUriCalled != nil)
        task.cancel()

        XCTAssertEqual(subject.state.vaultListSections, [])
        XCTAssertEqual(vaultRepository.ciphersAutofillPublisherUriCalled, "https://\(rpId)")
    }
} // swiftlint:disable:this file_length
