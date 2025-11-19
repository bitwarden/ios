import AppIntents
import BitwardenShared

/// App intent that log out all accounts.
@available(iOS 16.0, *)
struct LogoutAllAccountsIntent: AppIntent {
    static var title: LocalizedStringResource = "LogOutAllAccounts"

    static var description = IntentDescription("LogOutAllAccounts")

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

            try await appIntentMediator.logoutAllUsers()
            return .result(dialog: "AllAccountsHaveBeenLoggedOut")
        } catch let error as BitwardenShared.AppIntentError {
            throw error
        } catch {
            errorReporter.log(error: error)
            return .result(dialog: "AnErrorOccurredWhileTryingToLogOutAllAccounts")
        }
    }
}
