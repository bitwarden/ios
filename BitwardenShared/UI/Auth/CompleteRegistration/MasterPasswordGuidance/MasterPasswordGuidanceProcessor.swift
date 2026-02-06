import BitwardenKit

// MARK: - MasterPasswordGuidanceProcessor

/// The processor used to manage state and handle actions for the master password guidance screen.
///
class MasterPasswordGuidanceProcessor: StateProcessor<
    Void,
    MasterPasswordGuidanceAction,
    Void,
> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The delegate used to communiate saving a new generated password.
    private weak var delegate: MasterPasswordUpdateDelegate?

    // MARK: Initialization

    /// Creates a new `CompleteRegistrationProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate for the processor to notify saving a generated password.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        delegate: MasterPasswordUpdateDelegate?,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        super.init()
    }

    // MARK: Methods

    override func receive(_ action: MasterPasswordGuidanceAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismissPresented)
        case .generatePasswordPressed:
            coordinator.navigate(
                to: .masterPasswordGenerator,
                context: delegate,
            )
        }
    }
}
