import AVFoundation
import Foundation

// MARK: - CameraAuthorizationService

/// A service
protocol CameraAuthorizationService: AnyObject {
    /// The current camera authorization status that the user has granted this app.
    var cameraAuthorizationStatus: CameraAuthorizationStatus { get }

    /// Request camera access from the user.
    func requestCameraAuthorization() async -> CameraAuthorizationStatus
}

// MARK: - DefaultCamerAuthorizationService

class DefaultCameraAuthorizationService: CameraAuthorizationService {
    var cameraAuthorizationStatus: CameraAuthorizationStatus {
        CameraAuthorizationStatus(
            avAuthorizationStatus: AVCaptureDevice.authorizationStatus(for: .video)
        )
    }

    func requestCameraAuthorization() async -> CameraAuthorizationStatus {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                let status: CameraAuthorizationStatus
                if granted {
                    status = .authorized
                } else {
                    status = .denied
                }
                continuation.resume(returning: status)
            }
        }
    }
}
