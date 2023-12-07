import AVFoundation
import SwiftUI

// MARK: - ScanCodeProcessor

/// A processor that can process `ViewItemAction`s.
final class ScanCodeProcessor: StateProcessor<ScanCodeState, ScanCodeAction, ScanCodeEffect> {
    // MARK: Types

    typealias Services = HasCameraAuthorizationService
        & HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` for this processor.
    private let coordinator: any Coordinator<VaultItemRoute>

    /// The services used by this processor.
    private let services: Services

    // MARK: Intialization

    /// Creates a new `ScanCodeProcessor`.
    ///
    /// - Parameters:
    ///   - coordiantor: The `Coordinator` for this processor.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of this processor.
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
            services.cameraAuthorizationService.stopCameraSession()
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

    private func setupCamera() {
        do {
            try services.cameraAuthorizationService.startCameraSession()
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}
