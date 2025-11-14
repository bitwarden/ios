import BitwardenKit

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

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Initialize a `ExtensionActivationProcessor`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        services: Services,
        state: ExtensionActivationState,
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: ExtensionActivationEffect) async {
        switch effect {
        case .appeared:
            await services.autofillCredentialService.updateCredentialsInStore()
        }
    }

    override func receive(_ action: ExtensionActivationAction) {
        switch action {
        case .cancelTapped:
            appExtensionDelegate?.didCancel()
        }
    }
}
