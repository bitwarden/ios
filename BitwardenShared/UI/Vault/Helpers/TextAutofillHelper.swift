import BitwardenKit
import BitwardenResources
import BitwardenSdk

// MARK: - TextAutofillHelper

/// Protocol that helps to autofill text for any cipher type.
/// Note: This is momentary until the UI/UX is improved in the Autofill text flow.
protocol TextAutofillHelper: AnyObject {
    /// Handles autofilling text to insert from a cipher by presenting options for the user
    /// to choose which field they want to use for autofilling text.
    /// - Parameter cipherListView: The cipher to present options and get text to autofill.
    func handleCipherForAutofill(cipherListView: CipherListView) async throws

    /// Sets the delegate to used with this helper.
    func setTextAutofillHelperDelegate(_ delegate: TextAutofillHelperDelegate)
}

// MARK: - TextAutofillHelperDelegate

/// A delegate to be used with the `TextAutofillHelper`.
@MainActor
protocol TextAutofillHelperDelegate: AnyObject {
    /// Completes the text request with some text to insert.
    @available(iOSApplicationExtension 18.0, *)
    func completeTextRequest(text: String)

    /// Shows the alert.
    ///
    /// - Parameters:
    ///   - alert: The alert to show.
    ///   - onDismissed: An optional closure that is called when the alert is dismissed.
    ///
    func showAlert(_ alert: Alert, onDismissed: (() -> Void)?)
}

@MainActor
extension TextAutofillHelperDelegate {
    /// Shows the alert.
    ///
    /// - Parameters:
    ///   - alert: The alert to show.
    ///   - onDismissed: An optional closure that is called when the alert is dismissed.
    ///
    func showAlert(_ alert: Alert) {
        showAlert(alert, onDismissed: nil)
    }
}

// MARK: - DefaultTextAutofillHelper

/// Default implementation of `TextAutofillHelper`.
@available(iOS 18.0, *)
class DefaultTextAutofillHelper: TextAutofillHelper {
    // MARK: Properties

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used to record and send events.
    private let eventService: EventService

    /// The delegate to used with this helper.
    private weak var textAutofillHelperDelegate: TextAutofillHelperDelegate?

    /// The factory to create `TextAutofillOptionsHelper`.
    private let textAutofillOptionsHelperFactory: TextAutofillOptionsHelperFactory

    /// The repository used by the application to manage vault data for the UI layer.
    private let vaultRepository: VaultRepository

    // MARK: Initialization

    /// Initialize an `DefaultTextAutofillHelper`.
    ///
    /// - Parameters:
    ///   - errorReporter: The coordinator that handles navigation.
    ///   - eventService: The service used to record and send events.
    ///   - textAutofillOptionsHelperFactory: The factory to create `TextAutofillOptionsHelper`.
    ///   - vaultRepository: The repository used by the application to manage vault data for the UI layer.
    ///
    init(
        errorReporter: ErrorReporter,
        eventService: EventService,
        textAutofillOptionsHelperFactory: TextAutofillOptionsHelperFactory,
        vaultRepository: VaultRepository
    ) {
        self.errorReporter = errorReporter
        self.eventService = eventService
        self.textAutofillOptionsHelperFactory = textAutofillOptionsHelperFactory
        self.vaultRepository = vaultRepository
    }

    // MARK: Methods

    func handleCipherForAutofill(cipherListView: CipherListView) async throws {
        guard let cipherId = cipherListView.id,
              let cipherView = try await vaultRepository.fetchCipher(withId: cipherId) else {
            errorReporter.log(
                error: BitwardenError.generalError(
                    type: "TextAutofill: Handle Cipher For Autofill",
                    message: "Cipher Id was not set or cipher could not be fetched"
                )
            )
            await textAutofillHelperDelegate?.showAlert(.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.genericErrorMessage
            ))
            return
        }

        let options = await textAutofillOptionsHelperFactory
            .create(cipherView: cipherView)
            .getTextAutofillOptions(cipherView: cipherView)

        var alertActions = options.map { option in
            AlertAction(
                title: option.localizedOption,
                style: .default
            ) { [weak self] _, _ in
                guard let self else { return }
                await completeTextAutofill(
                    localizedOption: option.localizedOption,
                    textToInsert: option.textToInsert
                )
            }
        }
        if let customFieldAlertAction = getCustomFieldAlertActionIfNeeded(cipherView: cipherView) {
            alertActions.append(customFieldAlertAction)
        }

        guard !alertActions.isEmpty else {
            await textAutofillHelperDelegate?.showAlert(.defaultAlert(
                title: cipherView.name,
                message: Localizations.nothingAvailableToAutofill
            ))
            return
        }

        await textAutofillHelperDelegate?.showAlert(
            Alert(
                title: Localizations.autofill,
                message: nil,
                preferredStyle: .actionSheet,
                alertActions: alertActions + [AlertAction(title: Localizations.cancel, style: .cancel)]
            )
        )
    }

    /// Sets the delegate to used with this helper.
    func setTextAutofillHelperDelegate(_ delegate: TextAutofillHelperDelegate) {
        textAutofillHelperDelegate = delegate
    }

    // MARK: Private

    /// Completes the text autofill request with the specified value.
    /// - Parameters:
    ///   - localizedOption: The localized option selected.
    ///   - textToInsert: The value to be used to complete the request.
    private func completeTextAutofill(localizedOption: String, textToInsert: String) async {
        do {
            guard localizedOption != Localizations.verificationCode else {
                let key = TOTPKeyModel(authenticatorKey: textToInsert)
                if let codeModel = try await vaultRepository.refreshTOTPCode(for: key).codeModel {
                    await textAutofillHelperDelegate?.completeTextRequest(text: codeModel.code)
                }
                return
            }
            await textAutofillHelperDelegate?.completeTextRequest(text: textToInsert)
        } catch {
            await textAutofillHelperDelegate?.showAlert(
                .defaultAlert(
                    title: Localizations.anErrorHasOccurred,
                    message: Localizations.failedToGenerateVerificationCode
                )
            )
            errorReporter.log(error: error)
        }
    }

    /// Gets the custom field alert action if requirements are met.
    /// - Parameter cipherView: The cipher to get the custom fields.
    /// - Returns: The alert action if requirements are met.
    private func getCustomFieldAlertActionIfNeeded(cipherView: CipherView) -> AlertAction? {
        let availableCustomFields = cipherView.customFields.filter { field in
            field.type != .hidden || cipherView.viewPassword
        }
        guard !availableCustomFields.isEmpty else {
            return nil
        }

        return AlertAction(
            title: Localizations.customFields,
            style: .default
        ) { [weak self] _, _ in
            guard let self else { return }
            await showCustomFieldsOptionsForAutofill(availableCustomFields)
        }
    }

    /// Shows the custom fields for the user to choose from to autofill.
    /// - Parameters:
    ///   - customFields: The custom fields to show the options.
    private func showCustomFieldsOptionsForAutofill(_ customFields: [CustomFieldState]) async {
        let alertActions: [AlertAction] = customFields.compactMap { field in
            guard let name = field.name, let value = field.value else {
                return nil
            }

            return AlertAction(
                title: name,
                style: .default
            ) { [weak self] _, _ in
                guard let self else { return }
                await completeTextAutofill(
                    localizedOption: name,
                    textToInsert: value
                )
            }
        }
        await textAutofillHelperDelegate?.showAlert(
            Alert(
                title: Localizations.autofill,
                message: nil,
                preferredStyle: .actionSheet,
                alertActions: alertActions + [AlertAction(title: Localizations.cancel, style: .cancel)]
            )
        )
    }
}

// MARK: NoOpTextAutofillHelper

/// Helper to be used on iOS less than 18.0 given that we don't have autofilling text feature available.
class NoOpTextAutofillHelper: TextAutofillHelper {
    func handleCipherForAutofill(cipherListView: CipherListView) async {
        // No-op
    }

    /// Sets the delegate to used with this helper.
    func setTextAutofillHelperDelegate(_ delegate: TextAutofillHelperDelegate) {
        // No-op
    }
}
