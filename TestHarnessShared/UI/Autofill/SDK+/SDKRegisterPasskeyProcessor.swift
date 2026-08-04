import BitwardenKit

// MARK: - SDKRegisterPasskeyProcessor

/// The processor for the SDK-backed register passkey test screen.
///
final class SDKRegisterPasskeyProcessor: StateProcessor<
    SDKRegisterPasskeyState,
    SDKRegisterPasskeyAction,
    SDKRegisterPasskeyEffect,
> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    /// The service used to perform passkey registration through the Bitwarden SDK.
    private let sdkPasskeyService: SDKPasskeyService

    // MARK: Initialization

    /// Initializes an `SDKRegisterPasskeyProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - sdkPasskeyService: The service used to perform passkey registration through the
    ///     Bitwarden SDK.
    ///
    init(
        coordinator: AnyCoordinator<RootRoute, Void>,
        sdkPasskeyService: SDKPasskeyService,
    ) {
        self.coordinator = coordinator
        self.sdkPasskeyService = sdkPasskeyService
        super.init(state: SDKRegisterPasskeyState())
    }

    // MARK: Methods

    override func perform(_ effect: SDKRegisterPasskeyEffect) async {
        switch effect {
        case .registerPasskey:
            await registerPasskey()
        }
    }

    override func receive(_ action: SDKRegisterPasskeyAction) {
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

    /// Orchestrates state transitions and calls `sdkPasskeyService.registerPasskey`.
    private func registerPasskey() async {
        state.status = .inProgress
        do {
            let result = try await sdkPasskeyService.registerPasskey(
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
