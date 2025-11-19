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
        let errorReporter = ErrorReporterFactory.makeDefaultErrorReporter()
        let services = ServiceContainer.shared(
            errorReporter: { errorReporter },
        )
        let appIntentMediator = services.getAppIntentMediator()

        do {
            guard try await appIntentMediator.canRunAppIntents() else {
                return .result(dialog: "ThisOperationIsNotAllowedOnThisAccount")
            }

            try await appIntentMediator.lockAllUsers()

            return .result(dialog: "AllAccountsHaveBeenLocked")
        } catch let error as BitwardenShared.AppIntentError {
            throw error
        } catch {
            errorReporter.log(error: error)
            return .result(dialog: "AnErrorOccurredWhileTryingToLockTheCurrentUser")
        }
    }
}
