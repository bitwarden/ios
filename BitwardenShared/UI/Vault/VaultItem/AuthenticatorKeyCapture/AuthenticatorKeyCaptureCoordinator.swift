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
    /// - Parameters:
    ///   - coordinator: The coordinator sending the action.
    ///   - value: The code value that was captured.
    ///
    func didCompleteCapture(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        with value: String
    )

    /// Called when the scan flow requests the scan code screen.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator sending the action.
    func showCameraScan(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>
    )

    /// Called when the scan flow requests the manual entry screen.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator sending the action.
    func showManualEntry(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>
    )
}

// MARK: - AuthenticatorKeyCaptureCoordinator

/// A coordinator that manages navigation in the generator tab.
///
final class AuthenticatorKeyCaptureCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasCameraService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter

    // MARK: Private Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// A delegate that responds to events in this coordinator.
    private weak var delegate: AuthenticatorKeyCaptureDelegate?

    // MARK: Properties

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `AuthenticatorKeyCaptureCoordinator`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - delegate: An optional delegate that responds to events in this coordinator.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        delegate: AuthenticatorKeyCaptureDelegate?,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        self.delegate = delegate
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func handleEvent(_ event: AuthenticatorKeyCaptureEvent, context: AnyObject?) async {
        guard let stackNavigator else { return }
        if stackNavigator.isEmpty || delegate == nil {
            await showScanCode()
        } else {
            delegate?.showCameraScan(asAnyCoordinator())
        }
    }

    func navigate(
        to route: AuthenticatorKeyCaptureRoute,
        context: AnyObject?
    ) {
        switch route {
        case let .complete(value):
            delegate?.didCompleteCapture(
                asAnyCoordinator(),
                with: value.content
            )
        case let .dismiss(onDismiss):
            stackNavigator?.dismiss(completion: {
                onDismiss?.action()
            })
        case let .addManual(entry: authKey):
            delegate?.didCompleteCapture(
                asAnyCoordinator(),
                with: authKey
            )
        case .manualKeyEntry:
            guard let stackNavigator else { return }
            if stackNavigator.isEmpty || delegate == nil {
                showManualTotp()
            } else {
                delegate?.showManualEntry(asAnyCoordinator())
            }
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
    private func showScanCode() async {
        guard services.cameraService.deviceSupportsCamera(),
              let session = await getNewCameraSession() else {
            showManualTotp()
            return
        }
        let processor = ScanCodeProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: .init()
        )
        let store = Store(processor: processor)
        let view = ScanCodeView(
            cameraSession: session,
            store: store
        )
        stackNavigator?.replace(view)
    }

    /// Shows the totp manual setup screen.
    ///
    private func showManualTotp() {
        let deviceSupportsCamera = services.cameraService.deviceSupportsCamera() &&
            appExtensionDelegate?.isInAppExtension != true // Extensions don't allow camera access.
        let processor = ManualEntryProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: DefaultEntryState(
                deviceSupportsCamera: deviceSupportsCamera
            )
        )
        let view = ManualEntryView(
            store: Store(processor: processor)
        )
        stackNavigator?.replace(view)
    }
}

// MARK: - HasErrorAlertServices

extension AuthenticatorKeyCaptureCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
