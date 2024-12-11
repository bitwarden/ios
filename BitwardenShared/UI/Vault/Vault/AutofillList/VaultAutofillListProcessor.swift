import AuthenticationServices
@preconcurrency import BitwardenSdk

// MARK: - VaultAutofillListProcessor

/// The processor used to manage state and handle actions for the autofill list screen.
///
class VaultAutofillListProcessor: StateProcessor<// swiftlint:disable:this type_body_length
    VaultAutofillListState,
    VaultAutofillListAction,
    VaultAutofillListEffect
>, HasTOTPCodesSections {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasAutofillCredentialService
        & HasClientService
        & HasErrorReporter
        & HasEventService
        & HasFido2CredentialStore
        & HasFido2UserInterfaceHelper
        & HasPasteboardService
        & HasStateService
        & HasTOTPExpirationManagerFactory
        & HasTimeProvider
        & HasVaultRepository

    // MARK: Private Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// A helper that handles autofill for a selected cipher.
    private let autofillHelper: AutofillHelper

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultRoute, AuthAction>

    /// An object to manage TOTP code expirations and batch refresh calls for the vault list items.
    private var vaultItemsTotpExpirationManager: TOTPExpirationManager?

    /// An object to manage TOTP code expirations and batch refresh calls for search results.
    private var searchTotpExpirationManager: TOTPExpirationManager?

    /// The services used by this processor.
    private var services: Services

    // MARK: Calculated properties

    /// Gets the mode in which this autofill list should run.
    private var autofillListMode: AutofillListMode {
        autofillAppExtensionDelegate?.autofillListMode ?? .passwords
    }

    /// A delegate that is used to handle actions and retrieve information from within an Autofill extension
    /// on Fido2 flows.
    private var autofillAppExtensionDelegate: AutofillAppExtensionDelegate? {
        appExtensionDelegate as? AutofillAppExtensionDelegate
    }

    var vaultRepository: VaultRepository {
        services.vaultRepository
    }

    // MARK: Initialization

    /// Initialize a `VaultAutofillListProcessor`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        coordinator: AnyCoordinator<VaultRoute, AuthAction>,
        services: Services,
        state: VaultAutofillListState
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        autofillHelper = AutofillHelper(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator,
            services: services
        )
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)

        if autofillListMode == .totp {
            self.state.isAutofillingTotpList = true
            initTotpExpirationManagers()
        }
    }

    deinit {
        vaultItemsTotpExpirationManager?.cleanup()
        vaultItemsTotpExpirationManager = nil

        searchTotpExpirationManager?.cleanup()
        searchTotpExpirationManager = nil
    }

    // MARK: Methods

    override func perform(_ effect: VaultAutofillListEffect) async {
        switch effect {
        case let .vaultItemTapped(vaultItem):
            switch vaultItem.itemType {
            case let .cipher(cipher, fido2CredentialAutofillView):
                if #available(iOSApplicationExtension 17.0, *),
                   let autofillAppExtensionDelegate,
                   fido2CredentialAutofillView != nil || autofillAppExtensionDelegate.isCreatingFido2Credential {
                    await onCipherForFido2CredentialPicked(cipher: cipher)
                } else {
                    await autofillHelper.handleCipherForAutofill(cipherView: cipher) { [weak self] toastText in
                        self?.state.toast = Toast(title: toastText)
                    }
                }
            case .group:
                return
            case let .totp(_, totpModel):
                if #available(iOSApplicationExtension 18.0, *) {
                    autofillAppExtensionDelegate?.completeOTPRequest(code: totpModel.totpCode.code)
                }
                return
            }
        case .initFido2:
            if #available(iOSApplicationExtension 17.0, *) {
                await initFido2State()
            }
        case .loadData:
            await refreshProfileState()
        case let .profileSwitcher(profileEffect):
            await handle(profileEffect)
        case let .search(text):
            await searchVault(for: text)
        case .streamAutofillItems:
            await streamAutofillItems()
        case .streamShowWebIcons:
            for await value in await services.stateService.showWebIconsPublisher().values {
                state.showWebIcons = value
            }
        }
    }

    override func receive(_ action: VaultAutofillListAction) {
        switch action {
        case let .addTapped(fromFAB):
            state.profileSwitcherState.setIsVisible(false)

            guard #available(iOSApplicationExtension 17.0, *),
                  !fromFAB,
                  let autofillAppExtensionDelegate,
                  autofillAppExtensionDelegate.isCreatingFido2Credential else {
                coordinator.navigate(
                    to: .addItem(
                        allowTypeSelection: false,
                        group: .login,
                        newCipherOptions: createNewCipherOptions()
                    )
                )
                return
            }

            Task {
                await saveFido2CredentialAsNewLogin()
            }
        case .cancelTapped:
            appExtensionDelegate?.didCancel()
        case let .profileSwitcher(action):
            handle(action)
        case let .searchStateChanged(isSearching: isSearching):
            guard isSearching else { return }
            state.searchText = ""
            state.ciphersForSearch = []
            state.showNoResults = false
            state.profileSwitcherState.isVisible = false
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private Methods

    /// Creates a `NewCipherOptions` based on the context flow.
    func createNewCipherOptions() -> NewCipherOptions {
        if let autofillAppExtensionDelegate,
           autofillAppExtensionDelegate.isCreatingFido2Credential,
           let fido2CredentialNewView = services.fido2UserInterfaceHelper.fido2CredentialNewView {
            return NewCipherOptions(
                name: fido2CredentialNewView.rpName,
                uri: fido2CredentialNewView.rpId,
                username: fido2CredentialNewView.userName
            )
        }
        return NewCipherOptions(uri: appExtensionDelegate?.uri)
    }

    /// Handles receiving a `ProfileSwitcherAction`.
    ///
    /// - Parameter action: The `ProfileSwitcherAction` to handle.
    ///
    private func handle(_ profileSwitcherAction: ProfileSwitcherAction) {
        switch profileSwitcherAction {
        case let .accessibility(accessibilityAction):
            switch accessibilityAction {
            case .logout:
                // No-op: account logout not supported in the extension.
                break
            }
        default:
            handleProfileSwitcherAction(profileSwitcherAction)
        }
    }

    /// Handles receiving a `ProfileSwitcherEffect`.
    ///
    /// - Parameter action: The `ProfileSwitcherEffect` to handle.
    ///
    private func handle(_ profileSwitcherEffect: ProfileSwitcherEffect) async {
        switch profileSwitcherEffect {
        case let .accessibility(accessibilityAction):
            switch accessibilityAction {
            case .lock:
                // No-op: account lock not supported in the extension.
                break
            default:
                await handleProfileSwitcherEffect(profileSwitcherEffect)
            }
        default:
            await handleProfileSwitcherEffect(profileSwitcherEffect)
        }
    }

    /// Initilaizes the TOTP expiration managers so the TOTP codes are refreshed automatically.
    func initTotpExpirationManagers() {
        vaultItemsTotpExpirationManager = services.totpExpirationManagerFactory.create(
            onExpiration: { [weak self] expiredItems in
                guard let self else { return }
                Task {
                    await self.refreshTOTPCodes(for: expiredItems)
                }
            }
        )
        searchTotpExpirationManager = services.totpExpirationManagerFactory.create(
            onExpiration: { [weak self] expiredSearchItems in
                guard let self else { return }
                Task {
                    await self.refreshTOTPCodes(searchItems: expiredSearchItems)
                }
            }
        )
    }

    /// Refreshes the vault group's TOTP Codes.
    ///
    private func refreshTOTPCodes(for items: [VaultListItem]) async {
        guard !state.vaultListSections.isEmpty else {
            return
        }

        do {
            state.vaultListSections = try await refreshTOTPCodes(
                for: items,
                in: state.vaultListSections,
                using: vaultItemsTotpExpirationManager
            )
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Refreshes TOTP Codes for the search results.
    ///
    private func refreshTOTPCodes(searchItems: [VaultListItem]) async {
        let currentSearchResults = state.ciphersForSearch.first?.items ?? []
        do {
            state.ciphersForSearch = try await refreshTOTPCodes(
                for: searchItems,
                in: [
                    VaultListSection(id: "", items: currentSearchResults, name: ""),
                ],
                using: searchTotpExpirationManager
            )
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Searches the list of ciphers for those matching the search term.
    ///
    private func searchVault(for searchText: String) async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.ciphersForSearch = []
            state.showNoResults = false
            return
        }
        do {
            let searchResult = try await services.vaultRepository.searchCipherAutofillPublisher(
                availableFido2CredentialsPublisher: services
                    .fido2UserInterfaceHelper
                    .availableCredentialsForAuthenticationPublisher(),
                mode: autofillListMode,
                filterType: .allVaults,
                rpID: autofillAppExtensionDelegate?.rpID,
                searchText: searchText
            )
            for try await sections in searchResult {
                state.ciphersForSearch = sections
                state.showNoResults = sections.isEmpty
                if let section = sections.first, !section.items.isEmpty {
                    searchTotpExpirationManager?.configureTOTPRefreshScheduling(for: section.items)
                }
            }
        } catch {
            state.ciphersForSearch = []
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Streams the list of autofill items.
    ///
    private func streamAutofillItems() async {
        do {
            var uri = appExtensionDelegate?.uri
            if let autofillAppExtensionDelegate,
               autofillAppExtensionDelegate.isCreatingFido2Credential,
               let rpID = autofillAppExtensionDelegate.rpID {
                uri = "https://\(rpID)"
            }

            for try await sections in try await services.vaultRepository.ciphersAutofillPublisher(
                availableFido2CredentialsPublisher: services
                    .fido2UserInterfaceHelper
                    .availableCredentialsForAuthenticationPublisher(),
                mode: autofillListMode,
                rpID: autofillAppExtensionDelegate?.rpID,
                uri: uri
            ) {
                if autofillListMode == .totp, !sections.isEmpty {
                    vaultItemsTotpExpirationManager?.configureTOTPRefreshScheduling(for: sections.flatMap(\.items))
                }
                state.vaultListSections = sections
            }
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }
}

// MARK: - ProfileSwitcherHandler

extension VaultAutofillListProcessor: ProfileSwitcherHandler {
    var allowLockAndLogout: Bool {
        false
    }

    var profileServices: ProfileServices {
        services
    }

    var profileSwitcherState: ProfileSwitcherState {
        get {
            state.profileSwitcherState
        }
        set {
            state.profileSwitcherState = newValue
        }
    }

    var shouldHideAddAccount: Bool {
        true
    }

    var toast: Toast? {
        get {
            state.toast
        }
        set {
            state.toast = newValue
        }
    }

    func handleAuthEvent(_ authEvent: AuthEvent) async {
        guard case let .action(authAction) = authEvent else { return }
        await coordinator.handleEvent(authAction)
    }

    func showAddAccount() {
        // No-Op for the VaultAutofillListProcessor.
    }

    func showAlert(_ alert: Alert) {
        coordinator.showAlert(alert)
    }
}

// MARK: - Fido2UserInterfaceHelperDelegate

extension VaultAutofillListProcessor: Fido2UserInterfaceHelperDelegate {
    var isAutofillingFromList: Bool {
        autofillAppExtensionDelegate?.isAutofillingFido2CredentialFromList == true
    }

    func onNeedsUserInteraction() async throws {
        // No-Op for this processor.
    }

    func showAlert(_ alert: Alert, onDismissed: (() -> Void)?) {
        coordinator.showAlert(alert, onDismissed: onDismissed)
    }
}

// MARK: - Fido2 flows

@available(iOSApplicationExtension 17.0, *)
extension VaultAutofillListProcessor {
    // MARK: Methods

    /// Initializes Fido2 state and flows if needed.
    private func initFido2State() async {
        guard let autofillAppExtensionDelegate else {
            return
        }

        switch autofillAppExtensionDelegate.extensionMode {
        case let .registerFido2Credential(request):
            if let request = request as? ASPasskeyCredentialRequest,
               let credentialIdentity = request.credentialIdentity as? ASPasskeyCredentialIdentity {
                state.isCreatingFido2Credential = true
                state.emptyViewMessage = Localizations.noItemsForUri(credentialIdentity.relyingPartyIdentifier)
                state.emptyViewButtonText = Localizations.savePasskeyAsNewLogin
                services.fido2UserInterfaceHelper.setupDelegate(fido2UserInterfaceHelperDelegate: self)

                await handleFido2CredentialCreation(
                    autofillAppExtensionDelegate: autofillAppExtensionDelegate,
                    request: request,
                    credentialIdentity: credentialIdentity
                )
            }
        case let .autofillFido2VaultList(serviceIdentifiers, fido2RequestParameters):
            state.isAutofillingFido2List = true

            await handleFido2CredentialAutofill(
                autofillAppExtensionDelegate: autofillAppExtensionDelegate,
                serviceIdentifiers: serviceIdentifiers,
                fido2RequestParameters: fido2RequestParameters
            )
        default:
            break
        }
    }

    /// Handles Fido2 credential creation flow starting a request and completing the registration.
    /// - Parameters:
    ///   - autofillAppExtensionDelegate: The app extension delegate from the Autofill extension.
    ///   - request: The passkey credential request to create the Fido2 credential.
    ///   - credentialIdentity: The passkey credential identity from the request to create the Fido2 credential.
    func handleFido2CredentialAutofill(
        autofillAppExtensionDelegate: AutofillAppExtensionDelegate,
        serviceIdentifiers: [ASCredentialServiceIdentifier],
        fido2RequestParameters: PasskeyCredentialRequestParameters
    ) async {
        do {
            let assertionCredential = try await services.autofillCredentialService.provideFido2Credential(
                for: fido2RequestParameters,
                fido2UserInterfaceHelperDelegate: self
            )

            autofillAppExtensionDelegate.completeAssertionRequest(assertionCredential: assertionCredential)
        } catch {
            services.fido2UserInterfaceHelper.pickedCredentialForAuthentication(result: .failure(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Handles Fido2 credential creation flow starting a request and completing the registration.
    /// - Parameters:
    ///   - autofillAppExtensionDelegate: The app extension delegate from the Autofill extension.
    ///   - request: The passkey credential request to create the Fido2 credential.
    ///   - credentialIdentity: The passkey credential identity from the request to create the Fido2 credential.
    func handleFido2CredentialCreation(
        autofillAppExtensionDelegate: AutofillAppExtensionDelegate,
        request: ASPasskeyCredentialRequest,
        credentialIdentity: ASPasskeyCredentialIdentity
    ) async {
        do {
            let userVerificationPreference = Uv(preference: request.userVerificationPreference)
            let request = MakeCredentialRequest(
                clientDataHash: request.clientDataHash,
                rp: PublicKeyCredentialRpEntity(
                    id: credentialIdentity.relyingPartyIdentifier,
                    name: credentialIdentity.relyingPartyIdentifier
                ),
                user: PublicKeyCredentialUserEntity(
                    id: credentialIdentity.userHandle,
                    displayName: credentialIdentity.userName,
                    name: credentialIdentity.userName
                ),
                pubKeyCredParams: request.getPublicKeyCredentialParams(),
                excludeList: nil,
                options: Options(
                    rk: true,
                    uv: userVerificationPreference
                ),
                extensions: nil
            )
            services.fido2UserInterfaceHelper.setupCurrentUserVerificationPreference(
                userVerificationPreference: userVerificationPreference
            )
            let createdCredential = try await services.clientService.platform().fido2()
                .authenticator(
                    userInterface: services.fido2UserInterfaceHelper,
                    credentialStore: services.fido2CredentialStore
                )
                .makeCredential(request: request)

            autofillAppExtensionDelegate.completeRegistrationRequest(
                asPasskeyRegistrationCredential: ASPasskeyRegistrationCredential(
                    relyingParty: credentialIdentity.relyingPartyIdentifier,
                    clientDataHash: request.clientDataHash,
                    credentialID: createdCredential.credentialId,
                    attestationObject: createdCredential.attestationObject
                )
            )
        } catch {
            services.fido2UserInterfaceHelper.pickedCredentialForCreation(result: .failure(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Picks a cipher to use for the Fido2 process
    /// - Parameter cipher: Cipher to use.
    func onCipherForFido2CredentialPicked(cipher: CipherView) async {
        guard let autofillAppExtensionDelegate else {
            return
        }

        if autofillAppExtensionDelegate.isCreatingFido2Credential {
            guard let fido2CreationOptions = services.fido2UserInterfaceHelper.fido2CreationOptions else {
                coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
                return
            }

            if cipher.hasFido2Credentials {
                let alert = Alert.confirmation(
                    title: Localizations.thisItemAlreadyContainsAPasskeyAreYouSureYouWantToOverwriteTheCurrentPasskey
                ) { [weak self] in
                    await self?.checkUserAndDoPickedCredentialForCreation(
                        for: cipher,
                        fido2CreationOptions: fido2CreationOptions
                    )
                }
                coordinator.showAlert(alert)
                return
            }

            await checkUserAndDoPickedCredentialForCreation(for: cipher, fido2CreationOptions: fido2CreationOptions)
        } else if autofillAppExtensionDelegate.isAutofillingFido2CredentialFromList {
            services.fido2UserInterfaceHelper.pickedCredentialForAuthentication(
                result: .success(cipher)
            )
        }
    }

    /// Saves the new Fido2 credential as a new default cipher login.
    func saveFido2CredentialAsNewLogin() async {
        guard let fido2CreationOptions = services.fido2UserInterfaceHelper.fido2CreationOptions,
              let fido2CredentialNewView = services.fido2UserInterfaceHelper.fido2CredentialNewView else {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            return
        }

        let newCipher = CipherView(
            fido2CredentialNewView: fido2CredentialNewView,
            timeProvider: services.timeProvider
        )

        await checkUserAndDoPickedCredentialForCreation(for: newCipher, fido2CreationOptions: fido2CreationOptions)
    }

    /// Checks user and executes `pickedCredentialForCreation` for the Fido2 flow.
    /// - Parameters:
    ///   - cipher: Cipher to verify and pick.
    ///   - fido2CreationOptions: The options for checking the user on the Fido2 flow.
    func checkUserAndDoPickedCredentialForCreation(
        for cipher: CipherView,
        fido2CreationOptions: BitwardenSdk.CheckUserOptions
    ) async {
        do {
            let result = try await services.fido2UserInterfaceHelper.checkUser(
                userVerificationPreference: fido2CreationOptions.requireVerification,
                credential: cipher,
                shouldThrowEnforcingRequiredVerification: true
            )

            services.fido2UserInterfaceHelper.pickedCredentialForCreation(
                result: .success(
                    CheckUserAndPickCredentialForCreationResult(
                        cipher: CipherViewWrapper(cipher: cipher),
                        checkUserResult: CheckUserResult(userPresent: true, userVerified: result.userVerified)
                    )
                )
            )
        } catch UserVerificationError.cancelled {
            return
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }
} // swiftlint:disable:this file_length
