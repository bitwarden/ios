import BitwardenKit

// MARK: - RegisterPasskeyProcessor

/// The processor for the SDK-backed register passkey test screen.
///
final class RegisterPasskeyProcessor: StateProcessor<
    RegisterPasskeyState,
    RegisterPasskeyAction,
    RegisterPasskeyEffect,
> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    /// The service used to perform passkey registration through the Bitwarden SDK.
    private let passkeyService: PasskeyService

    // MARK: Initialization

    /// Initializes an `RegisterPasskeyProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - passkeyService: The service used to perform passkey registration through the
    ///     Bitwarden SDK.
    ///
    init(
        coordinator: AnyCoordinator<RootRoute, Void>,
        passkeyService: PasskeyService,
    ) {
        self.coordinator = coordinator
        self.passkeyService = passkeyService
        super.init(state: RegisterPasskeyState())
    }

    // MARK: Methods

    override func perform(_ effect: RegisterPasskeyEffect) async {
        switch effect {
        case .registerPasskey:
            await registerPasskey()
        }
    }

    override func receive(_ action: RegisterPasskeyAction) {
        switch action {
        case let .displayNameChanged(newValue):
            state.displayName = newValue
            state.status = .idle
        case let .rpIdChanged(newValue):
            state.rpId = newValue
            state.status = .idle
        case let .userNameChanged(newValue):
            state.userName = newValue
            state.status = .idle
        }
    }

    // MARK: Private

    /// Orchestrates state transitions and calls `passkeyService.registerPasskey`.
    private func registerPasskey() async {
        state.status = .inProgress
        do {
            let result = try await passkeyService.registerPasskey(
                rpId: state.rpId,
                userName: state.userName,
                displayName: state.displayName,
            )
            state.status = .success(credentialId: result.credentialId.base64EncodedString())
        } catch {
            state.status = .failure(error.localizedDescription)
        }
    }
}
