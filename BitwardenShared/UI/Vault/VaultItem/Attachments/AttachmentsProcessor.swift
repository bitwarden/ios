// MARK: - MoveToOrganizationProcessor

/// The processor used to manage state and handle actions for `AttachmentsView`.
///
class AttachmentsProcessor: StateProcessor<AttachmentsState, AttachmentsAction, AttachmentsEffect> {
    // MARK: Types

    typealias Services = HasCameraService
        & HasErrorReporter
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultItemRoute>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `MoveToOrganizationProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultItemRoute>,
        services: Services,
        state: AttachmentsState
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AttachmentsEffect) async {
        switch effect {
        case .save:
            break
        }
    }

    override func receive(_ action: AttachmentsAction) {
        switch action {
        case let .cameraViewPresentedChanged(isPresented):
            state.cameraViewPresented = isPresented
        case .chooseFilePressed:
            coordinator.showAlert(.attachmentOptions(handler: attachmentOptionSelected))
        case .dismissPressed:
            coordinator.navigate(to: .dismiss())
        case let .imageChanged(image):
            state.image = image
        }
    }

    // MARK: Private Methods

    /// Handle an attachment option being selected.
    private func attachmentOptionSelected(alertAction: AlertAction) async {
        switch alertAction.title {
        case Localizations.photos:
            // TODO: BIT-1447
            break
        case Localizations.camera:
            await showCamera()
        case Localizations.browse:
            // TODO: BIT-1449
            break
        default:
            break
        }
    }

    /// Check if the user can access the camera, and if so, show the camera.
    private func showCamera() async {
        // Display an alert if the user hasn't or can't enable camera permissions.
        guard services.cameraService.deviceSupportsCamera(),
              await services.cameraService.checkStatusOrRequestCameraAuthorization() == .authorized
        else {
            // TODO: BIT-1466 prompt user to enable camera permissions
            return
        }
        state.cameraViewPresented = true
    }
}
