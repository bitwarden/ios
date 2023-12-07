import AVFoundation
import Foundation

// MARK: - CameraAuthorizationService

/// A service that is used to check for and request camera authorization from the user.
///
protocol CameraAuthorizationService: AnyObject {
    /// Checks the current camera authorization status that the user has granted this app, and if
    /// necessary, requests authorization from the user.
    ///
    func checkStatusOrRequestCameraAuthorization() async -> CameraAuthorizationStatus

    /// Gets an `AVCaptureSession` to use for the app to scan QR codes.
    ///
    ///  - Returns: An optional AVCaptureSession: non-nil if authorized.
    ///
    func getCameraSession() -> AVCaptureSession?

    /// Starts  the `AVCaptureSession` to use for the app to scan QR codes.
    ///
    func startCameraSession() throws

    /// Stops  the `AVCaptureSession`.
    ///
    func stopCameraSession()
}

// MARK: - CameraServiceError

enum CameraServiceError: Error, Equatable {
    case unableToStartCaptureSession
}

// MARK: - DefaultCamerAuthorizationService

class DefaultCameraAuthorizationService: CameraAuthorizationService {
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
