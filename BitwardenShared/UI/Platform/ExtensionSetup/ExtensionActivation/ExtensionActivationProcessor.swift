import BitwardenKit
import BitwardenResources

// MARK: - ExtensionActivationProcessor

/// The processor used to manage state and handle actions for the extension activation screen.
///
class ExtensionActivationProcessor: StateProcessor<
    ExtensionActivationState,
    ExtensionActivationAction,
    ExtensionActivationEffect,
> {
    // MARK: Types

    typealias Services = HasAutofillCredentialService
        & HasConfigService
        & HasErrorReporter

    // MARK: Private Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<ExtensionSetupRoute, Void>

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Initialize a `ExtensionActivationProcessor`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        coordinator: AnyCoordinator<ExtensionSetupRoute, Void>,
        services: Services,
        state: ExtensionActivationState,
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: ExtensionActivationEffect) async {
        switch effect {
        case .appeared:
            await updateCredentialsInStore()
        }
    }

    override func receive(_ action: ExtensionActivationAction) {
        switch action {
        case .cancelTapped:
            appExtensionDelegate?.didCancel()
        }
    }

    // MARK: Private methods

    /// Updates the credentials from Bitwarden vault to the OS Store.
    func updateCredentialsInStore() async {
        coordinator.showLoadingOverlay(title: Localizations.settingUpAutofill)
        defer { coordinator.hideLoadingOverlay() }
        await services.autofillCredentialService.updateCredentialsInStore()
    }
}
