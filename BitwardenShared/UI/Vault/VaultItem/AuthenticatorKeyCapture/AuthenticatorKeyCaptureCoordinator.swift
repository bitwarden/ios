import AVFoundation
import SwiftUI

// MARK: - AuthenticatorKeyCaptureDelegate

/// An object that is signaled when specific circumstances in the scan flow have been
/// encountered.
///
@MainActor
protocol AuthenticatorKeyCaptureDelegate: AnyObject {
    /// Called when the scan flow has been completed.
    ///
    /// - Parameter value: The code value that was captured.
    ///
    func didCompleteCapture(with value: String)
}

// MARK: - AuthenticatorKeyCaptureCoordinator

/// A coordinator that manages navigation in the generator tab.
///
final class AuthenticatorKeyCaptureCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasCameraService
        & HasErrorReporter

    // MARK: Private Properties

    /// A delegate that responds to events in this coordinator.
    private weak var delegate: AuthenticatorKeyCaptureDelegate?

    // MARK: Properties

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    let stackNavigator: StackNavigator

    /// A variable to store the present route.
    private var presentScreen: AuthenticatorKeyCaptureScreen?

    // MARK: Initialization

    /// Creates a new `AuthenticatorKeyCaptureCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: An optional delegate that responds to events in this coordinator.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        delegate: AuthenticatorKeyCaptureDelegate?,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.delegate = delegate
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: AuthenticatorKeyCaptureRoute, context: AnyObject?) {
        switch route {
        case let .complete(value):
            delegate?.didCompleteCapture(with: value.content)
        case let .dismiss(onDismiss):
            stackNavigator.dismissTopMost(completion: { [weak self] in
                onDismiss?.action()
                self?.presentScreen = nil
            })
        case let .screen(screen):
            switch screen {
            case .manual:
                switch presentScreen {
                case .manual:
                    return
                case .scan:
                    stackNavigator.dismiss(completion: { [weak self] in
                        self?.presentScreen = nil
                        self?.showManualTotp()
                    })
                    return
                case nil:
                    presentScreen = nil
                    showManualTotp()
                    return
                }
            case .scan:
                guard services.cameraService.deviceSupportsCamera() else {
                    navigate(to: .screen(.manual), context: context)
                    return
                }
                switch presentScreen {
                case .manual:
                    stackNavigator.dismiss(completion: { [weak self] in
                        self?.presentScreen = nil
                        self?.showScanCode()
                    })
                    return
                case .scan:
                    return
                case nil:
                    presentScreen = nil
                    showScanCode()
                    return
                }
            }
        case let .addManual(entry: authKey):
            delegate?.didCompleteCapture(with: authKey)
        }
    }

    func start() {}

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
            presentScreen = .scan
        }
    }

    /// Shows the totp manual setup screen.
    ///
    private func showManualTotp() {
        guard presentScreen != .manual else {
            return
        }
        let processor = ManualEntryProcessor(
            coordinator: self,
            services: services,
            state: DefaultEntryState(
                deviceSupportsCamera: services.cameraService.deviceSupportsCamera()
            )
        )
        let view = ManualEntryView(
            store: Store(processor: processor)
        )
        let navWrapped = NavigationView { view }
        stackNavigator.present(navWrapped)
        presentScreen = .manual
    }
}
