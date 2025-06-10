import BitwardenSdk

// MARK: - MasterPasswordRepromptHelper

/// A protocol for a helper that's used to present the master password reprompt alert if a cipher
/// has master password reprompt enabled and the user has a master password.
///
protocol MasterPasswordRepromptHelper {
    /// Reprompts the user for their master password if the cipher has master password reprompt
    /// enabled and the user has a master password.
    ///
    /// - Parameters:
    ///   - cipherView: The `CipherView` used to determine if master password reprompt is enabled.
    ///   - completion: A closure that is called if master password reprompt is successful or it
    ///     wasn't required. This *isn't* called if master password reprompt is unsuccessful.
    ///
    func repromptForMasterPasswordIfNeeded(
        cipherView: CipherView,
        completion: @escaping @MainActor () async -> Void
    ) async

    /// Reprompts the user for their master password if the cipher has master password reprompt
    /// enabled and the user has a master password.
    ///
    /// - Parameters:
    ///   - cipherListView: The `cipherListView` used to determine if master password reprompt is enabled.
    ///   - completion: A closure that is called if master password reprompt is successful or it
    ///     wasn't required. This *isn't* called if master password reprompt is unsuccessful.
    ///
    func repromptForMasterPasswordIfNeeded(
        cipherListView: CipherListView,
        completion: @escaping @MainActor () async -> Void
    ) async
}

// MARK: - DefaultMasterPasswordRepromptHelper

/// A default implementation of `MasterPasswordRepromptHelper`.
///
@MainActor
class DefaultMasterPasswordRepromptHelper<Route, Event>: MasterPasswordRepromptHelper {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<Route, Event>

    /// The services used by this helper.
    private let services: Services

    // MARK: Initialization

    /// Initialize a `DefaultMasterPasswordRepromptHelper`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by this helper.
    init(
        coordinator: AnyCoordinator<Route, Event>,
        services: Services
    ) {
        self.coordinator = coordinator
        self.services = services
    }

    // MARK: Methods

    func repromptForMasterPasswordIfNeeded(
        cipherListView: CipherListView,
        completion: @escaping @MainActor () async -> Void
    ) async {
        await repromptForMasterPasswordIfNeeded(reprompt: cipherListView.reprompt, completion: completion)
    }

    func repromptForMasterPasswordIfNeeded(
        cipherView: CipherView,
        completion: @escaping @MainActor () async -> Void
    ) async {
        await repromptForMasterPasswordIfNeeded(reprompt: cipherView.reprompt, completion: completion)
    }

    // MARK: Private

    /// Presents the master password reprompt alert and calls the completion handler when the user's
    /// master password has been confirmed.
    ///
    /// - Parameter completion: A completion handler that is called when the user's master password
    ///     has been confirmed.
    ///
    private func presentMasterPasswordRepromptAlert(completion: @escaping () async -> Void) async {
        let alert = Alert.masterPasswordPrompt { password in
            do {
                let isValid = try await self.services.authRepository.validatePassword(password)
                guard isValid else {
                    self.coordinator.showAlert(.defaultAlert(title: Localizations.invalidMasterPassword))
                    return
                }
                await completion()
            } catch {
                self.services.errorReporter.log(error: error)
                await self.coordinator.showErrorAlert(error: error)
            }
        }
        coordinator.showAlert(alert)
    }

    /// Reprompts the user for their master password if the reprompt type enables master password
    /// reprompt and the user has a master password.
    ///
    /// - Parameters:
    ///   - reprompt: The `CipherRepromptType` used to determine if master password reprompt is enabled.
    ///   - completion: A closure that is called if master password reprompt is successful or it
    ///     wasn't required. This *isn't* called if master password reprompt is unsuccessful.
    ///
    private func repromptForMasterPasswordIfNeeded(
        reprompt: BitwardenSdk.CipherRepromptType,
        completion: @escaping @MainActor () async -> Void
    ) async {
        do {
            guard try await services.authRepository.shouldPerformMasterPasswordReprompt(reprompt: reprompt) else {
                await completion()
                return
            }
            await presentMasterPasswordRepromptAlert(completion: completion)
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
