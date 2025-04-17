import BitwardenKit
import BitwardenSdk

/// Protocol for a factory to create `TextAutofillOptionsHelper` for each cipher type.
protocol TextAutofillOptionsHelperFactory {
    /// Creates a `TextAutofillOptionsHelper` for a cipher depending on the type.
    func create(cipherView: CipherView) -> TextAutofillOptionsHelper
}

/// Default implementation of the `TextAutofillOptionsHelperFactory`.
struct DefaultTextAutofillOptionsHelperFactory: TextAutofillOptionsHelperFactory {
    // MARK: Properties

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The repository used by the application to manage vault data for the UI layer.
    let vaultRepository: VaultRepository

    // MARK: Methods

    func create(cipherView: CipherView) -> TextAutofillOptionsHelper {
        return switch cipherView.type {
        case .login:
            LoginTextAutofillOptionsHelper(
                errorReporter: errorReporter,
                vaultRepository: vaultRepository
            )
        case .secureNote:
            SecureNoteTextAutofillOptionsHelper()
        case .card:
            CardTextAutofillOptionsHelper()
        case .identity:
            IdentityTextAutofillOptionsHelper()
        case .sshKey:
            SSHKeyTextAutofillOptionsHelper()
        }
    }
}
