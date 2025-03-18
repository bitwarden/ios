import AppIntents
import BitwardenShared

/// App intent that locks all accounts.
@available(iOS 16.0, *)
struct LockAllAccountsIntent: AppIntent {
    static var title: LocalizedStringResource = "LockAllAccounts"

    static var description = IntentDescription("LockAllAccounts")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let errorReporter = ServiceContainer.createDefaultErrorReporter()
        do {
            let services = ServiceContainer(
                appContext: .appIntent(.lockAll),
                errorReporter: errorReporter
            )
            let appProcessor = AppProcessor(appModule: DefaultAppModule(services: services), services: services)
            let appIntentMediator = appProcessor.getAppIntentMediator()

            guard await appIntentMediator.canRunAppIntents() else {
                return .result(dialog: "ThisOperationIsNotAllowedOnThisAccount")
            }

            try await appIntentMediator.lockAllUsers()
            return .result(dialog: "AllAccountsHaveBeenLocked")
        } catch {
            errorReporter.log(error: error)
            return .result(dialog: "AnErrorOccurredWhileTryingToLockTheCurrentUser")
        }
    }
}
