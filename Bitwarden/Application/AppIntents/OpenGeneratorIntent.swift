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
        let services = ServiceContainer.shared(
            errorReporter: { ErrorReporterFactory.makeDefaultErrorReporter() }
        )
        let appIntentMediator = services.getAppIntentMediator()

        guard try await appIntentMediator.canRunAppIntents() else {
            return .result()
        }

        await appIntentMediator.openGenerator()

        return .result()
    }
}
