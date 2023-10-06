import BitwardenSdk
import Combine

// MARK: - CreateAccountProcessor

/// The processor used to manage state and handle actions for the create account screen.
///
class CreateAccountProcessor: StateProcessor<CreateAccountState, CreateAccountAction, CreateAccountEffect> {
    // MARK: Types

    typealias Services = HasAccountAPIService
        & HasClientAuth

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute>

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `CreateAccountProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute>,
        services: Services,
        state: CreateAccountState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: CreateAccountEffect) async {
        switch effect {
        case .createAccount:
            await createAccount()
        }
    }

    override func receive(_ action: CreateAccountAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .emailTextChanged(text):
            state.emailText = text
        case let .passwordHintTextChanged(text):
            state.passwordHintText = text
        case let .passwordTextChanged(text):
            state.passwordText = text
        case let .retypePasswordTextChanged(text):
            state.retypePasswordText = text
        case let .toggleCheckDataBreaches(isOn: isToggleOn):
            state.isCheckDataBreachesToggleOn = isToggleOn
        case .togglePasswordVisibility:
            state.arePasswordsVisible.toggle()
        case let .toggleTermsAndPrivacy(isOn: isToggleOn):
            state.isTermsAndPrivacyToggleOn = isToggleOn
        }
    }

    /// Creates the user's account with their provided credentials.
    ///
    private func createAccount() async {
        do {
            guard state.isTermsAndPrivacyToggleOn else {
                // TODO: BIT-681
                return
            }

            let kdf: Kdf = .pbkdf2(iterations: NonZeroU32(KdfConfig().kdfIterations))

            let keys = try await services.clientAuth.makeRegisterKeys(
                email: state.emailText,
                password: state.passwordText,
                kdf: kdf
            )

            let hashedPassword = try await services.clientAuth.hashPassword(
                email: state.emailText,
                password: state.passwordText,
                kdfParams: kdf
            )

            if state.isCheckDataBreachesToggleOn {
                _ = try await services.accountAPIService.checkDataBreaches(password: state.passwordText)
            }

            _ = try await services.accountAPIService.createNewAccount(
                body: CreateAccountRequestModel(
                    email: state.emailText,
                    kdfConfig: KdfConfig(),
                    key: keys.encryptedUserKey,
                    keys: KeysRequestModel(
                        publicKey: keys.keys.public,
                        encryptedPrivateKey: keys.keys.private
                    ),
                    masterPasswordHash: hashedPassword,
                    masterPasswordHint: state.passwordHintText
                )
            )
        } catch {
            // TODO: BIT-681
        }
    }
}
