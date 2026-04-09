import BitwardenKit
import Combine
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

    // MARK: Properties

    /// A publisher that publishes the processor's scan result when it changes.
    var qrScanPublisher: AnyPublisher<[ScanResult], Never> {
        qrScanResultSubject.eraseToAnyPublisher()
    }

    // MARK: Private Properties

    /// The `Coordinator` responsible for navigation-related actions.
    private let coordinator: any Coordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>

    /// The services used by this processor, including camera authorization and error reporting.
    private let services: Services

    /// A subject containing the scan code results.
    private var qrScanResultSubject = CurrentValueSubject<[ScanResult], Never>([])

    // MARK: Initialization

    /// Creates a new `ScanCodeProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` responsible for managing navigation based on actions received.
    ///   - services: The services used by this processor, including access to the camera and error reporting.
    ///   - state: The initial state of this processor, representing the UI's state.
    ///
    init(
        coordinator: any Coordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        services: Services,
        state: ScanCodeState,
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    override func perform(_ effect: ScanCodeEffect) async {
        switch effect {
        case .appeared:
            await setupCameraResultsObservation()
        case .disappeared:
            services.cameraService.stopCameraSession()
        }
    }

    override func receive(_ action: ScanCodeAction) {
        switch action {
        case .dismissPressed:
            coordinator.navigate(to: .dismiss())
        case .manualEntryPressed:
            coordinator.navigate(to: .manualKeyEntry)
        }
    }

    /// Sets up the camera for scanning QR codes.
    ///
    /// This method checks for camera support and initiates the camera session. If an error occurs,
    /// it logs the error through the provided error reporting service.
    ///
    private func setupCameraResultsObservation() async {
        guard services.cameraService.deviceSupportsCamera() else {
            coordinator.navigate(to: .manualKeyEntry)
            return
        }

        for await value in services.cameraService.getScanResultPublisher() {
            guard let value else { continue }
            coordinator.navigate(to: .complete(value: value))
            return
        }
    }
}
