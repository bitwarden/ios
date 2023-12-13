import AVFoundation
import Foundation

// MARK: - CameraService

/// A service that is used to manage camera access and use for the user.
///
protocol CameraService: AnyObject {
    /// Checks the current camera authorization status and requests authorization if necessary.
    ///
    /// This method first checks the current camera authorization status granted to the app.
    /// If the status is not determined, it requests authorization from the user.
    ///
    /// - Returns: The current `CameraAuthorizationStatus` of the app.
    ///
    func checkStatusOrRequestCameraAuthorization() async -> CameraAuthorizationStatus

    /// Checks if the device has camera capabilities.
    ///
    /// This method verifies if the current device is equipped with a camera.
    ///
    /// - Returns: A flag indicating whether the device has a camera (`true`) or not (`false`).
    ///
    func deviceSupportsCamera() -> Bool

    /// Retrieves an `AVCaptureSession` for scanning QR codes.
    ///
    /// - Returns: An `AVCaptureSession` if the app is authorized; otherwise, `nil`.
    ///
    func getCameraSession() -> AVCaptureSession?

    /// Starts the camera session for QR code scanning.
    ///
    /// - Throws: An error if the camera session cannot be started.
    ///
    func startCameraSession() throws

    /// Stops the camera session.
    ///
    /// This method stops the ongoing camera session, typically used when the app no longer needs
    /// to scan QR codes or when the relevant UI is no longer visible.
    ///
    func stopCameraSession()
}

// MARK: - CameraServiceError

enum CameraServiceError: Error, Equatable {
    case unableToStartCaptureSession
}

// MARK: - DefaultCamerAuthorizationService

class DefaultCameraService: CameraService {
    var cameraSession: AVCaptureSession!

    func checkStatusOrRequestCameraAuthorization() async -> CameraAuthorizationStatus {
        let status = CameraAuthorizationStatus(
            avAuthorizationStatus: AVCaptureDevice.authorizationStatus(for: .video)
        )

        if status == .notDetermined {
            return await requestCameraAuthorization()
        }
        return status
    }

    func deviceSupportsCamera() -> Bool {
        var acceptedDevices: [AVCaptureDevice.DeviceType] = [
            .builtInDualCamera,
            .builtInDualWideCamera,
            .builtInTripleCamera,
            .builtInTrueDepthCamera,
            .builtInWideAngleCamera,
            .builtInTelephotoCamera,
            .builtInUltraWideCamera,
        ]
        if #available(iOSApplicationExtension 15.4, *) {
            acceptedDevices.append(.builtInLiDARDepthCamera)
        }
        if #available(iOSApplicationExtension 17.0, *) {
            acceptedDevices.append(.continuityCamera)
        }
        let videoDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: acceptedDevices,
            mediaType: .video,
            position: .unspecified
        ).devices

        return !videoDevices.isEmpty
    }

    func getCameraSession() -> AVCaptureSession? {
        let status = CameraAuthorizationStatus(
            avAuthorizationStatus: AVCaptureDevice.authorizationStatus(for: .video)
        )
        guard case .authorized = status else {
            cameraSession = nil
            return nil
        }
        if cameraSession == nil {
            cameraSession = AVCaptureSession()
        }

        return cameraSession
    }

    func startCameraSession() throws {
        guard let cameraSession,
              let videoDevice = AVCaptureDevice.default(for: .video) else {
            throw CameraServiceError.unableToStartCaptureSession
        }
        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        if cameraSession.canAddInput(videoInput) {
            cameraSession.addInput(videoInput)
        }
        DispatchQueue.global(qos: .userInitiated).async {
            cameraSession.startRunning()
        }
    }

    func stopCameraSession() {
        guard let cameraSession else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            cameraSession.stopRunning()
        }
    }

    /// Request camera access from the user.
    ///
    private func requestCameraAuthorization() async -> CameraAuthorizationStatus {
        if await AVCaptureDevice.requestAccess(for: .video) {
            .authorized
        } else {
            .denied
        }
    }
}
