import AuthenticationServices
import BitwardenSdk

// MARK: - VaultAutofillListProcessor

/// The processor used to manage state and handle actions for the autofill list screen.
///
class VaultAutofillListProcessor: StateProcessor<
    VaultAutofillListState,
    VaultAutofillListAction,
    VaultAutofillListEffect
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasClientService
        & HasErrorReporter
        & HasEventService
        & HasFido2CredentialStore
        & HasFido2UserInterfaceHelper
        & HasPasteboardService
        & HasVaultRepository

    // MARK: Private Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// A helper that handles autofill for a selected cipher.
    private let autofillHelper: AutofillHelper

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultRoute, AuthAction>

    /// The services used by this processor.
    private var services: Services

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
    }

    // MARK: Methods

    override func perform(_ effect: VaultAutofillListEffect) async {
        switch effect {
        case let .vaultItemTapped(vaultItem):
            switch vaultItem.itemType {
            case let .cipher(cipher, fido2CredentialAutofillView):
                if #available(iOSApplicationExtension 17.0, *),
                   fido2CredentialAutofillView != nil {
                    await onCipherForFido2CredentialPicked(cipher: cipher)
                } else {
                    await autofillHelper.handleCipherForAutofill(cipherView: cipher) { [weak self] toastText in
                        self?.state.toast = Toast(text: toastText)
                    }
                }
            case .group:
                return
            case .totp:
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
        }
    }

    override func receive(_ action: VaultAutofillListAction) {
        switch action {
        case .addTapped:
            state.profileSwitcherState.setIsVisible(false)
            coordinator.navigate(
                to: .addItem(
                    allowTypeSelection: false,
                    group: .login,
                    newCipherOptions: createNewCipherOptions()
                )
            )
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
        if let fido2AppExtensionDelegate = appExtensionDelegate as? Fido2AppExtensionDelegate,
           fido2AppExtensionDelegate.isCreatingFido2Credential,
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
                searchText: searchText,
                filterType: .allVaults
            )
            for try await ciphers in searchResult {
                // TODO: PM-8713 Update searchCipherAutofillPublisher with the proper item in the VaultRepository
                state.ciphersForSearch = ciphers.compactMap { .init(cipherView: $0) }
                state.showNoResults = ciphers.isEmpty
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
            for try await ciphers in try await services.vaultRepository.ciphersAutofillPublisher(
                uri: appExtensionDelegate?.uri
            ) {
                // TODO: PM-8713 Move this to a vaultAutofillListPublisher in the VaultRepository
                state.ciphersForAutofill = ciphers.compactMap { .init(cipherView: $0) }
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

// MARK: - Fido2UserVerificationMediatorDelegate

extension VaultAutofillListProcessor: Fido2UserVerificationMediatorDelegate {
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
        guard let fido2AppExtensionDelegate = appExtensionDelegate as? Fido2AppExtensionDelegate else {
            return
        }

        services.fido2UserInterfaceHelper.setupDelegate(fido2UserVerificationMediatorDelegate: self)

        if case let .registerFido2Credential(request) = fido2AppExtensionDelegate.extensionMode,
           let request = request as? ASPasskeyCredentialRequest,
           let credentialIdentity = request.credentialIdentity as? ASPasskeyCredentialIdentity {
            await handleFido2CredentialCreation(
                fido2appExtensionDelegate: fido2AppExtensionDelegate,
                request: request,
                credentialIdentity: credentialIdentity
            )
        }
    }

    /// Handles Fido2 credential creation flow starting a request and completing the registration.
    /// - Parameters:
    ///   - fido2appExtensionDelegate: The app extension delegate from the Autofill extension.
    ///   - request: The passkey credential request to create the Fido2 credential.
    ///   - credentialIdentity: The passkey credential identity from the request to create the Fido2 credential.
    func handleFido2CredentialCreation(
        fido2appExtensionDelegate: Fido2AppExtensionDelegate,
        request: ASPasskeyCredentialRequest,
        credentialIdentity: ASPasskeyCredentialIdentity
    ) async {
        do {
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
                    uv: Uv(preference: request.userVerificationPreference)
                ),
                extensions: nil
            )
            let createdCredential = try await services.clientService.platform().fido2()
                .authenticator(
                    userInterface: services.fido2UserInterfaceHelper,
                    credentialStore: services.fido2CredentialStore
                )
                .makeCredential(request: request)

            fido2appExtensionDelegate.completeRegistrationRequest(
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

    /// Picks a cipher to use for the Fido2 creation process
    /// - Parameter cipher: Cipher to use.
    func onCipherForFido2CredentialPicked(cipher: CipherView) async {
        guard let fido2appExtensionDelegate = appExtensionDelegate as? Fido2AppExtensionDelegate,
              fido2appExtensionDelegate.isCreatingFido2Credential else {
            return
        }
        services.fido2UserInterfaceHelper.pickedCredentialForCreation(
            result: .success(
                CheckUserAndPickCredentialForCreationResult(
                    cipher: CipherViewWrapper(cipher: cipher),
                    // TODO: PM-9849 add user verification
                    checkUserResult: CheckUserResult(userPresent: true, userVerified: true)
                )
            )
        )
    }
}
