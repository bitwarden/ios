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
        & HasItemRepository
        & HasPasteboardService
        & HasTOTPService
        & HasTimeProvider

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
            let newLoginTotp = try await services.itemRepository.refreshTOTPCode(for: calculationKey)

            guard case let .data(tokenItemState) = state.loadingState else { return }

            var newState = tokenItemState
            newState.totpState = newLoginTotp
            state.loadingState = .data(newState)
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Stream the cipher details.
    private func streamTokenDetails() async {
        do {
            guard let token = try await services.itemRepository.fetchItem(withId: itemId)
            else { return }

            var totpState = LoginTOTPState(token.login?.totp)
            if let key = totpState.authKeyModel,
               let updatedState = try? await services.itemRepository.refreshTOTPCode(for: key) {
                totpState = updatedState
            }

            guard var newState = ViewTokenState(cipherView: token) else { return }
            if case var .data(tokenState) = newState.loadingState {
                tokenState.totpState = totpState
                newState.loadingState = .data(tokenState)
            }
            state = newState
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}
