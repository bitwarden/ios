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
        requestValueDialog: "Number of words must be between 3 and 20."
    )
    var numberOfWords: Int?

    @Parameter(
        title: "Capitalize",
        description: "Whether to capitalize each word."
    )
    var capitalize: Bool?

    @Parameter(
        title: "Include numbers",
        description: "Whether to include numbers."
    )
    var includeNumber: Bool?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let services = ServiceContainer(
            appContext: .appIntent(.generatePassphrase),
            errorReporter: ErrorReporterFactory.makeDefaultErrorReporter()
        )
        let appProcessor = AppProcessor(appModule: DefaultAppModule(services: services), services: services)
        let appIntentMediator = appProcessor.getAppIntentMediator()

        guard await appIntentMediator.canRunAppIntents() else {
            throw AppIntentError.notAllowed
        }

        guard let numberOfWords else {
            throw $numberOfWords.needsValueError()
        }

        let passphrase = try await appIntentMediator.generatePassphrase(
            settings: PassphraseGeneratorRequest(
                numWords: UInt8(numberOfWords),
                wordSeparator: "-",
                capitalize: capitalize ?? true,
                includeNumber: includeNumber ?? true
            )
        )

        return .result(value: passphrase, dialog: "Passphrase: \(passphrase)")
    }
}
