import BitwardenResources
import Foundation
import OSLog

// MARK: - EditAuthenticatorItemDelegate

/// An object that is notified about editing events to an item
///
protocol AuthenticatorItemOperationDelegate: AnyObject {
    /// Called when the authenticator item is deleted
    func itemDeleted()
}

// MARK: - EditAuthenticatorItemProcessor

/// The processor used to manage state and handle actions/effects for the edit item screen
final class EditAuthenticatorItemProcessor: StateProcessor<
    EditAuthenticatorItemState,
    EditAuthenticatorItemAction,
    EditAuthenticatorItemEffect
> {
    // MARK: Types

    typealias Services = HasAuthenticatorItemRepository
        & HasErrorReporter

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<AuthenticatorItemRoute, AuthenticatorItemEvent>

    /// The delegate that is notified when and item has been deleted.
    private weak var delegate: AuthenticatorItemOperationDelegate?

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `EditAuthenticatorItemProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state for the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthenticatorItemRoute, AuthenticatorItemEvent>,
        delegate: AuthenticatorItemOperationDelegate?,
        services: Services,
        state: EditAuthenticatorItemState
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: EditAuthenticatorItemEffect) async {
        switch effect {
        case .appeared:
            break
        case .savePressed:
            await saveItem()
        case .deletePressed:
            let alert = Alert.confirmDeleteItem { [weak self] in
                await self?.deleteItem()
            }
            coordinator.showAlert(alert)
        }
    }

    override func receive(_ action: EditAuthenticatorItemAction) {
        switch action {
        case let .accountNameChanged(accountName):
            state.accountName = accountName
        case .advancedPressed:
            state.isAdvancedExpanded.toggle()
        case let .algorithmChanged(algorithm):
            state.algorithm = algorithm
        case let .digitsChanged(digits):
            state.digits = digits
        case .dismissPressed:
            coordinator.navigate(to: .dismiss())
        case let .favoriteChanged(newValue):
            state.isFavorited = newValue
        case let .issuerChanged(issuer):
            state.issuer = issuer
        case let .nameChanged(newValue):
            state.issuer = newValue
        case let .periodChanged(period):
            state.period = period
        case let .secretChanged(secret):
            state.secret = secret
            state.totpState = LoginTOTPState(secret)
        case let .toggleSecretVisibilityChanged(isVisible):
            state.isSecretVisible = isVisible
        case let .toastShown(toast):
            state.toast = toast
        case let .totpTypeChanged(type):
            state.totpType = type
        }
    }

    // MARK: Private Methods

    /// Handles dismissing the processor.
    ///
    /// - Parameter didAddItem: `true` if a new cipher was added or `false` if the user is
    ///     dismissing the view without saving.
    ///
    private func handleDismiss(didAddItem: Bool = false) {
        coordinator.navigate(to: .dismiss())
    }

    /// Deletes the item currently stored in `state`.
    ///
    private func deleteItem() async {
        do {
            try await services.authenticatorItemRepository.deleteAuthenticatorItem(state.id)
            coordinator.navigate(to: .dismiss(DismissAction(action: { [weak self] in
                self?.delegate?.itemDeleted()
            })))
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Saves the item currently stored in `state`.
    ///
    private func saveItem() async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            try EmptyInputValidator(fieldName: Localizations.name)
                .validate(input: state.issuer)
            try EmptyInputValidator(fieldName: Localizations.key)
                .validate(input: state.secret)
            coordinator.showLoadingOverlay(title: Localizations.saving)
            switch state.configuration {
            case .add:
                return
            case let .existing(authenticatorItemView: authenticatorItemView):
                guard let secret = state.totpState.authKeyModel?.base32Key else { return }
                let newAuthenticatorItemView: AuthenticatorItemView
                switch state.totpType {
                case .steam:
                    newAuthenticatorItemView = AuthenticatorItemView(
                        favorite: state.isFavorited,
                        id: authenticatorItemView.id,
                        name: state.issuer,
                        totpKey: "steam://\(secret)",
                        username: state.accountName
                    )
                case .totp:
                    let newOtpUri = OTPAuthModel(
                        accountName: state.accountName.nilIfEmpty,
                        algorithm: state.algorithm,
                        digits: state.digits,
                        issuer: state.issuer.nilIfEmpty,
                        period: state.period.rawValue,
                        secret: secret
                    )

                    newAuthenticatorItemView = AuthenticatorItemView(
                        favorite: state.isFavorited,
                        id: authenticatorItemView.id,
                        name: state.issuer,
                        totpKey: newOtpUri.otpAuthUri,
                        username: state.accountName
                    )
                }
                try await updateAuthenticatorItem(authenticatorItem: newAuthenticatorItemView)
            }
        } catch let error as InputValidationError {
            coordinator.showAlert(Alert.inputValidationAlert(error: error))
            return
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Updates the item currently in `state`.
    ///
    private func updateAuthenticatorItem(authenticatorItem: AuthenticatorItemView) async throws {
        try await services.authenticatorItemRepository.updateAuthenticatorItem(authenticatorItem)
        coordinator.hideLoadingOverlay()
        coordinator.navigate(to: .dismiss())
    }
}
