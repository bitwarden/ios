import BitwardenKit
import BitwardenSdk

/// A wrapper for `TextAutofillHelper` which adds the logic for master password reprompt if necessary.
@available(iOS 18.0, *)
class TextAutofillHelperRepromptWrapper: TextAutofillHelper {
    // MARK: Properties

    /// The repository used by the application to manage auth data for the UI layer.
    private let authRepository: AuthRepository

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The actual text autofill helper
    private let textAutofillHelper: TextAutofillHelper

    /// The delegate to used with this helper.
    private weak var textAutofillHelperDelegate: TextAutofillHelperDelegate?

    /// Helper to execute user verifications.
    private var userVerificationHelper: UserVerificationHelper

    /// Initializes a `TextAutofillHelperRepromptWrapper`.
    /// - Parameters:
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - textAutofillHelper: The actual text autofill helper.
    ///   - userVerificationHelper: Helper to execute user verifications.
    init(
        authRepository: AuthRepository,
        errorReporter: ErrorReporter,
        textAutofillHelper: TextAutofillHelper,
        userVerificationHelper: UserVerificationHelper,
    ) {
        self.authRepository = authRepository
        self.errorReporter = errorReporter
        self.userVerificationHelper = userVerificationHelper
        self.textAutofillHelper = textAutofillHelper
        self.userVerificationHelper.userVerificationDelegate = self
    }

    func handleCipherForAutofill(cipherListView: CipherListView) async throws {
        do {
            if cipherListView.reprompt == .password,
               try await authRepository.hasMasterPassword(),
               try await userVerificationHelper.verifyMasterPassword() != .verified {
                return
            }

            try await textAutofillHelper.handleCipherForAutofill(cipherListView: cipherListView)
        } catch UserVerificationError.cancelled {
            // No-op
        }
    }

    func setTextAutofillHelperDelegate(_ delegate: any TextAutofillHelperDelegate) {
        textAutofillHelperDelegate = delegate
        textAutofillHelper.setTextAutofillHelperDelegate(delegate)
    }
}

// MARK: - UserVerificationDelegate

@available(iOSApplicationExtension 18.0, *)
extension TextAutofillHelperRepromptWrapper: UserVerificationDelegate {
    func showAlert(_ alert: Alert) {
        textAutofillHelperDelegate?.showAlert(alert)
    }

    func showAlert(_ alert: Alert, onDismissed: (() -> Void)?) {
        textAutofillHelperDelegate?.showAlert(alert, onDismissed: onDismissed)
    }
}
