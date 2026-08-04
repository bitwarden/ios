import BitwardenKit

// MARK: - SDKUsePasskeyProcessor

/// The processor for the SDK-backed use passkey test screen.
///
final class SDKUsePasskeyProcessor: StateProcessor<
    SDKUsePasskeyState,
    SDKUsePasskeyAction,
    SDKUsePasskeyEffect,
> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    /// The service used to perform passkey assertion through the Bitwarden SDK.
    private let sdkPasskeyService: SDKPasskeyService

    // MARK: Initialization

    /// Initializes an `SDKUsePasskeyProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - sdkPasskeyService: The service used to perform passkey assertion through the
    ///     Bitwarden SDK.
    ///
    init(
        coordinator: AnyCoordinator<RootRoute, Void>,
        sdkPasskeyService: SDKPasskeyService,
    ) {
        self.coordinator = coordinator
        self.sdkPasskeyService = sdkPasskeyService
        super.init(state: SDKUsePasskeyState())
    }

    // MARK: Methods

    override func perform(_ effect: SDKUsePasskeyEffect) async {
        switch effect {
        case .assertPasskey:
            await assertPasskey()
        }
    }

    override func receive(_ action: SDKUsePasskeyAction) {
        switch action {
        case let .rpIdChanged(newValue):
            state.rpId = newValue
            state.status = .idle
        }
    }

    // MARK: Private

    /// Orchestrates state transitions and calls `sdkPasskeyService.assertPasskey`.
    private func assertPasskey() async {
        state.status = .inProgress
        do {
            let result = try await sdkPasskeyService.assertPasskey(rpId: state.rpId)
            state.status = .success(
                credentialId: result.credentialId.base64EncodedString(),
                userName: result.selectedCredential.credential.userName,
            )
        } catch {
            state.status = .failure(error.localizedDescription)
        }
    }
}
