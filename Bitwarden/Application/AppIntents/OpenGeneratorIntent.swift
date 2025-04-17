import AppIntents
import BitwardenShared

/// App intent that opens the generator view.
@available(iOS 16.0, *)
struct OpenGeneratorIntent: AppIntent {
    static var title: LocalizedStringResource = "OpenGenerator"

    static var description = IntentDescription("OpenGenerator")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let services = ServiceContainer(
            appContext: .appIntent(.generatePassphrase),
            errorReporter: ErrorReporterFactory.makeDefaultErrorReporter()
        )
        let appProcessor = AppProcessor(appModule: DefaultAppModule(services: services), services: services)
        let appIntentMediator = appProcessor.getAppIntentMediator()

        guard await appIntentMediator.canRunAppIntents() else {
            return .result()
        }

        await appIntentMediator.openGenerator()

        return .result()
    }
}
