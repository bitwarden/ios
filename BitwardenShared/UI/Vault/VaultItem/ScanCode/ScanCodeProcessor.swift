import SwiftUI

// MARK: - ScanCodeProcessor

/// A processor that can process `ScanCodeAction`s.
///
/// This class is responsible for handling actions and effects related to scanning QR codes.
///
final class ScanCodeProcessor: StateProcessor<ScanCodeState, ScanCodeAction, ScanCodeEffect> {
    // MARK: Types

    /// A typealias for the services required by this processor.
    typealias Services = HasCameraService
        & HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` responsible for navigation-related actions.
    private let coordinator: any Coordinator<VaultItemRoute>

    /// The services used by this processor, including camera authorization and error reporting.
    private let services: Services

    // MARK: Intialization

    /// Creates a new `ScanCodeProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` responsible for managing navigation based on actions received.
    ///   - services: The services used by this processor, including access to the camera and error reporting.
    ///   - state: The initial state of this processor, representing the UI's state.
    ///
    init(
        coordinator: any Coordinator<VaultItemRoute>,
        services: Services,
        state: ScanCodeState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    override func perform(_ effect: ScanCodeEffect) async {
        switch effect {
        case .appeared:
            setupCamera()
        case .disappeared:
            services.cameraService.stopCameraSession()
        }
    }

    override func receive(_ action: ScanCodeAction) {
        switch action {
        case .dismissPressed:
            coordinator.navigate(to: .dismiss)
        case .manualEntryPressed:
            // TODO: BIT-1065: Scan Logic
            // https://livefront.atlassian.net/browse/BIT-1065
            break
        }
    }

    /// Sets up the camera for scanning QR codes.
    ///
    /// This method checks for camera support and initiates the camera session. If an error occurs,
    /// it logs the error through the provided error reporting service.
    ///
    private func setupCamera() {
        guard services.cameraService.deviceSupportsCamera() else {
            coordinator.navigate(to: .setupTotpManual)
            return
        }
        do {
            try services.cameraService.startCameraSession()
        } catch {
            services.errorReporter.log(error: error)
            coordinator.navigate(to: .setupTotpManual)
        }
    }
}
