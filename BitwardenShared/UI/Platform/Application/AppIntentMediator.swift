import BitwardenKit
import BitwardenSdk
import Foundation

/// A mediator to process `AppIntent` actions.
public protocol AppIntentMediator {
    /// Whether app intents can be run.
    @available(iOSApplicationExtension 16, *)
    func canRunAppIntents() async throws -> Bool

    /// Generates a passphrase.
    func generatePassphrase(settings: PassphraseGeneratorRequest) async throws -> String

    /// Locks all available users.
    func lockAllUsers() async throws

    /// Logs out all users.
    func logoutAllUsers() async throws

    /// Opens the generator view.
    func openGenerator() async
}

/// The default implementation of the `AppIntentMediator`.
struct DefaultAppIntentMediator: AppIntentMediator {
    /// The repository used by the application to manage auth data for the UI layer.
    let authRepository: AuthRepository
    /// The service to get server-specified configuration.
    let configService: ConfigService
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
    /// The repository used by the application to manage generator data for the UI layer.
    let generatorRepository: GeneratorRepository
    /// The service used by the application to manage account state.
    let stateService: StateService

    /// Initializes a `DefaultAppIntentMediator`.
    /// - Parameters:
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - configService: The service to get server-specified configuration.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    public init(
        authRepository: AuthRepository,
        configService: ConfigService,
        errorReporter: ErrorReporter,
        generatorRepository: GeneratorRepository,
        stateService: StateService
    ) {
        self.authRepository = authRepository
        self.configService = configService
        self.errorReporter = errorReporter
        self.generatorRepository = generatorRepository
        self.stateService = stateService
    }

    @available(iOSApplicationExtension 16, *)
    func canRunAppIntents() async throws -> Bool {
        do {
            return try await stateService.getSiriAndShortcutsAccess()
        } catch StateServiceError.noAccounts, StateServiceError.noActiveAccount {
            throw AppIntentError.noActiveAccount
        } catch {
            errorReporter.log(error: error)
            return false
        }
    }

    func generatePassphrase(settings: PassphraseGeneratorRequest) async throws -> String {
        try await generatorRepository.generatePassphrase(
            settings: settings,
            isPreAuth: true
        )
    }

    func lockAllUsers() async throws {
        try await authRepository.lockAllVaults(isManuallyLocking: true)
        await stateService.addPendingAppIntentAction(.lockAll)
    }

    func logoutAllUsers() async throws {
        guard let accounts = try? await stateService.getAccounts(), !accounts.isEmpty else {
            return
        }

        var allAccountsLoggedOut = true
        for account in accounts {
            do {
                try await authRepository.logout(userId: account.profile.userId, userInitiated: true)
            } catch {
                allAccountsLoggedOut = false
                errorReporter.log(error: error)
            }
        }

        if allAccountsLoggedOut {
            await stateService.addPendingAppIntentAction(.logOutAll)
        }
    }

    func openGenerator() async {
        await stateService.addPendingAppIntentAction(.openGenerator)
    }
}

/// The errors that can be thrown by app intents.
@available(iOS 16, *)
public enum AppIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noActiveAccount
    case notAllowed

    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noActiveAccount:
            "ThereIsNoActiveAccount"
        case .notAllowed:
            "ThisOperationIsNotAllowedOnThisAccount"
        }
    }
}
