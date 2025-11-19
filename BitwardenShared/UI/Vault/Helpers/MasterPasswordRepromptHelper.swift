import BitwardenKit
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
    ///   - cipherId: The identifier for a cipher used to determine if master password reprompt is enabled.
    ///   - completion: A closure that is called if master password reprompt is successful or it
    ///     wasn't required. This *isn't* called if master password reprompt is unsuccessful.
    ///
    func repromptForMasterPasswordIfNeeded(
        cipherId: String,
        completion: @escaping @MainActor () async -> Void,
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
        completion: @escaping @MainActor () async -> Void,
    ) async

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
        completion: @escaping @MainActor () async -> Void,
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
        & HasVaultRepository

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<Route, Event>

    /// The services used by this helper.
    private let services: Services

    /// The helper to execute user verification flows.
    private let userVerificationHelper: UserVerificationHelper

    // MARK: Initialization

    /// Initialize a `DefaultMasterPasswordRepromptHelper`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by this helper.
    ///   - userVerificationHelper: The helper to execute user verification flows.
    init(
        coordinator: AnyCoordinator<Route, Event>,
        services: Services,
        userVerificationHelper: UserVerificationHelper,
    ) {
        self.coordinator = coordinator
        self.services = services
        self.userVerificationHelper = userVerificationHelper
    }

    // MARK: Methods

    func repromptForMasterPasswordIfNeeded(
        cipherId: String,
        completion: @escaping @MainActor () async -> Void,
    ) async {
        do {
            guard let cipherView = try await services.vaultRepository.fetchCipher(withId: cipherId) else {
                throw BitwardenError.dataError("A cipher with the specified ID was not found.")
            }
            await repromptForMasterPasswordIfNeeded(reprompt: cipherView.reprompt, completion: completion)
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }

    func repromptForMasterPasswordIfNeeded(
        cipherListView: CipherListView,
        completion: @escaping @MainActor () async -> Void,
    ) async {
        await repromptForMasterPasswordIfNeeded(reprompt: cipherListView.reprompt, completion: completion)
    }

    func repromptForMasterPasswordIfNeeded(
        cipherView: CipherView,
        completion: @escaping @MainActor () async -> Void,
    ) async {
        await repromptForMasterPasswordIfNeeded(reprompt: cipherView.reprompt, completion: completion)
    }

    // MARK: Private

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
        completion: @escaping @MainActor () async -> Void,
    ) async {
        do {
            guard try await services.authRepository.shouldPerformMasterPasswordReprompt(reprompt: reprompt) else {
                await completion()
                return
            }

            guard try await userVerificationHelper.verifyMasterPassword() == .verified else { return }
            await completion()
        } catch UserVerificationError.cancelled {
            // No-op
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
