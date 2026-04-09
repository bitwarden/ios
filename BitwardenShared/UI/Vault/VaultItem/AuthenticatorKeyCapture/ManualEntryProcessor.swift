import BitwardenKit
import SwiftUI

// MARK: - ManualEntryProcessor

/// A processor that can process `ManualEntryAction`s.
///
/// This class is responsible for handling actions and effects related to manually entry of authenticator keys.
///
final class ManualEntryProcessor: StateProcessor<ManualEntryState, ManualEntryAction, ManualEntryEffect> {
    // MARK: Types

    /// A typealias for the services required by this processor.
    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` responsible for navigation-related actions.
    private let coordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>

    /// The services used by this processor, including camera authorization and error reporting.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `ManualEntryProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` responsible for managing navigation based on actions received.
    ///   - services: The services used by this processor, including access to the camera and error reporting.
    ///   - state: The initial state of this processor, representing the UI's state.
    ///
    init(
        coordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        services: Services,
        state: ManualEntryState,
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    override func perform(_ effect: ManualEntryEffect) async {
        switch effect {
        case .scanCodePressed:
            await coordinator.handleEvent(.showScanCode, context: nil)
        }
    }

    override func receive(_ action: ManualEntryAction) {
        switch action {
        case .dismissPressed:
            coordinator.navigate(to: .dismiss())
        case let .addPressed(code: authKey):
            coordinator.navigate(to: .addManual(entry: authKey))
        case let .authenticatorKeyChanged(newKey):
            state.authenticatorKey = newKey
        }
    }
}
