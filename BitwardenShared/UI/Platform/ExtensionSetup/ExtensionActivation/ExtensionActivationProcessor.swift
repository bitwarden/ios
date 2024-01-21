// MARK: - ExtensionActivationProcessor

/// The processor used to manage state and handle actions for the extension activation screen.
///
class ExtensionActivationProcessor: StateProcessor<
    ExtensionActivationState,
    ExtensionActivationAction,
    Void
> {
    // MARK: Private Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    // MARK: Initialization

    /// Initialize a `ExtensionActivationProcessor`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - state: The initial state of the processor.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        state: ExtensionActivationState
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: ExtensionActivationAction) {
        switch action {
        case .cancelTapped:
            appExtensionDelegate?.didCancel()
        }
    }
}
