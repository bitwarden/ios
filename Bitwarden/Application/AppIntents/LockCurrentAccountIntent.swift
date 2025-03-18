import AppIntents
import BitwardenShared

/// App intent that locks the current account.
@available(iOS 16.0, *)
struct LockCurrentAccountIntent: AppIntent {
    static var title: LocalizedStringResource = "LockCurrentAccount"

    static var description = IntentDescription("LockCurrentAccount")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let services = ServiceContainer(
            appContext: .appIntent(.lockCurrentUser),
            errorReporter: ServiceContainer.createDefaultErrorReporter()
        )
        let appProcessor = AppProcessor(appModule: DefaultAppModule(services: services), services: services)
        let appIntentMediator = appProcessor.getAppIntentMediator()

        guard await appIntentMediator.canRunAppIntents() else {
            return .result(dialog: "ThisOperationIsNotAllowedOnThisAccount")
        }

        await appIntentMediator.lockCurrentUser()
        return .result(dialog: "AccountLockedSuccessfully")
    }
}
