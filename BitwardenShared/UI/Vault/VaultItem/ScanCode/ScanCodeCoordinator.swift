import AVFoundation
import SwiftUI

// MARK: - ScanCodeCoordinatorDelegate

/// An object that is signaled when specific circumstances in the generator flow have been
/// encountered.
///
@MainActor
protocol ScanCodeCoordinatorDelegate: AnyObject {
    /// Called when the scan flow has been completed.
    ///
    /// - Parameter value: The code value that was captured.
    ///
    func didCompleteScan(with value: String)
}

// MARK: - ScanCodeCoordinator

/// A coordinator that manages navigation in the generator tab.
///
final class ScanCodeCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasCameraService

    // MARK: Private Properties

    /// A delegate that responds to events in this coordinator.
    private weak var delegate: ScanCodeCoordinatorDelegate?

    // MARK: Properties

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    let stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `ScanCodeCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: An optional delegate that responds to events in this coordinator.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        delegate: ScanCodeCoordinatorDelegate?,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.delegate = delegate
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: ScanCodeRoute, context: AnyObject?) {
        switch route {
        case let .complete(value):
            delegate?.didCompleteScan(with: value.content)
        case .dismiss:
            stackNavigator.dismiss()
        case .scanCode:
            showScanCode()
        case .setupTotpManual:
            showManualTotp()
        }
    }

    func start() {
        start(manualEntry: false)
    }

    func start(manualEntry: Bool = false) {
        navigate(to: manualEntry ? .setupTotpManual : .scanCode)
    }

    // MARK: Private Methods

    /// Gets a new camera session for the scan code view.
    ///
    /// - Returns: An optional `AVCaptureSession`, nil on error.
    ///
    private func getNewCameraSession() async -> AVCaptureSession? {
        guard services.cameraService.deviceSupportsCamera(),
              case .authorized = await
              services.cameraService.checkStatusOrRequestCameraAuthorization() else {
            return nil
        }
        do {
            return try await services.cameraService.startCameraSession()
        } catch {
            services.errorReporter.log(error: error)
            return nil
        }
    }

    /// Shows the scan code screen.
    ///
    /// - Parameter type: The type to initialize this generator screen with. If a value is provided,
    ///   then the type field in the generator screen will be hidden, to eliminate the ability to
    ///   switch between the various types.
    ///
    private func showScanCode() {
        Task {
            guard services.cameraService.deviceSupportsCamera(),
                  case .authorized = await
                  services.cameraService.checkStatusOrRequestCameraAuthorization(),
                  let session = await getNewCameraSession() else {
                showManualTotp()
                return
            }
            let processor = ScanCodeProcessor(
                coordinator: self,
                services: services,
                state: .init()
            )
            let store = Store(processor: processor)
            let view = ScanCodeView(
                cameraSession: session,
                store: store
            )
            let navWrapped = view.navStackWrapped
            stackNavigator.present(navWrapped, animated: true, overFullscreen: true)
        }
    }

    /// Shows the totp manual setup screen.
    ///
    private func showManualTotp() {
        let view = Text("Manual Totp")
        let navWrapped = NavigationView { view }
        stackNavigator.present(navWrapped)
    }
}

/// A route to a specific screen in the scan code screen.
///
public enum ScanCodeRoute: Equatable, Hashable {
    /// A route to complete the scan with the provided value
    case complete(value: ScanResult)

    /// A route that dismisses a presented sheet.
    case dismiss

    /// A route to the scan code screen.
    case scanCode

    /// A route to the manual TOTP entry screen.
    case setupTotpManual
}
