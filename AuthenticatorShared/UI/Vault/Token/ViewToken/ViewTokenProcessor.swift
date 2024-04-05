import BitwardenSdk
import Foundation

// MARK: - ViewTokenProcessor

/// The processor used to manage state and handle actions for the view token screen.
final class ViewTokenProcessor: StateProcessor<
    ViewTokenState,
    ViewTokenAction,
    ViewTokenEffect
> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasPasteboardService
        & HasTOTPService
        & HasTimeProvider
        & HasTokenRepository

    // MARK: Properties

    /// The `Coordinator` that handles navigation, typically a `TokenCoordinator`.
    private let coordinator: AnyCoordinator<TokenRoute, TokenEvent>

    /// The ID of the item being viewed.
    private let itemId: String

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `ViewTokenProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` for this processor.
    ///   - itemId: The ID of the item that is being viewed.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: AnyCoordinator<TokenRoute, TokenEvent>,
        itemId: String,
        services: Services,
        state: ViewTokenState
    ) {
        self.coordinator = coordinator
        self.itemId = itemId
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: ViewTokenEffect) async {
        switch effect {
        case .appeared:
            await streamTokenDetails()
        case .totpCodeExpired:
            await updateTOTPCode()
        }
    }

    override func receive(_ action: ViewTokenAction) {
        switch action {
        case let .toastShown(newValue):
            state.toast = newValue
        case let .copyPressed(value):
            services.pasteboardService.copy(value)
            state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.verificationCode))
        case .editPressed:
            break
        }
    }
}

private extension ViewTokenProcessor {
    // MARK: Private Methods

    /// Updates the TOTP code for the view.
    func updateTOTPCode() async {
        guard case let .data(tokenItemState) = state.loadingState,
              let calculationKey = tokenItemState.totpState.authKeyModel
        else { return }
        do {
            let code = try await services.tokenRepository.refreshTotpCode(for: calculationKey)

            guard case let .data(tokenItemState) = state.loadingState else { return }

            let newTotpState = LoginTOTPState(
                authKeyModel: calculationKey,
                codeModel: code
            )

            var newState = tokenItemState
            newState.totpState = newTotpState
            state.loadingState = .data(newState)
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Stream the token details.
    private func streamTokenDetails() async {
        do {
            guard let token = try await services.tokenRepository.fetchToken(withId: itemId)
            else { return }

            let code = try await services.tokenRepository.refreshTotpCode(for: token.key)
            guard var newTokenState = ViewTokenState(token: token) else { return }
            if case var .data(tokenState) = newTokenState.loadingState {
                let totpState = LoginTOTPState(
                    authKeyModel: token.key,
                    codeModel: code
                )
                tokenState.totpState = totpState
                newTokenState.loadingState = .data(tokenState)
            }
            state = newTokenState
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}
