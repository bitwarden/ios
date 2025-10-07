import AppIntents
import BitwardenSdk
import BitwardenShared

/// App intent that generates a password.
@available(iOS 16.0, *)
struct GeneratePassphraseIntent: AppIntent {
    static var title: LocalizedStringResource = "GeneratePassphrase"

    static var description = IntentDescription("GeneratePassphrase")

    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "Number of words",
        description: "The number of words to include in the passphrase.",
        inclusiveRange: (3, 20),
        requestValueDialog: "Number of words must be between 3 and 20.",
    )
    var numberOfWords: Int?

    @Parameter(
        title: "Capitalize",
        description: "Whether to capitalize each word.",
    )
    var capitalize: Bool?

    @Parameter(
        title: "Include numbers",
        description: "Whether to include numbers.",
    )
    var includeNumber: Bool?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let services = ServiceContainer.shared(
            errorReporter: { ErrorReporterFactory.makeDefaultErrorReporter() },
        )
        let appIntentMediator = services.getAppIntentMediator()

        guard try await appIntentMediator.canRunAppIntents() else {
            throw BitwardenShared.AppIntentError.notAllowed
        }

        guard let numberOfWords else {
            throw $numberOfWords.needsValueError()
        }

        let passphrase = try await appIntentMediator.generatePassphrase(
            settings: PassphraseGeneratorRequest(
                numWords: UInt8(numberOfWords),
                wordSeparator: "-",
                capitalize: capitalize ?? true,
                includeNumber: includeNumber ?? true,
            ),
        )

        return .result(value: passphrase, dialog: "Passphrase: \(passphrase)")
    }
}
