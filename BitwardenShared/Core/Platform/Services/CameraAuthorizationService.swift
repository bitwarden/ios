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
}

// MARK: - DefaultCamerAuthorizationService

class DefaultCameraAuthorizationService: CameraAuthorizationService {
    func checkStatusOrRequestCameraAuthorization() async -> CameraAuthorizationStatus {
        let status = CameraAuthorizationStatus(
            avAuthorizationStatus: AVCaptureDevice.authorizationStatus(for: .video)
        )

        if status == .notDetermined {
            return await requestCameraAuthorization()
        }
        return status
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
