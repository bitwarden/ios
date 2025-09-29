import AVFoundation
import Foundation
import OSLog

/// All enumerations of the user's decision to authorize camera access.
enum CameraAuthorizationStatus: Equatable {
    /// Camera access has been authorized.
    case authorized

    /// Camera access has been denied.
    case denied

    /// Camera access has not been determined yet.
    case notDetermined

    /// This app isn't permitted to use the camera due to an OS decision.
    case restricted
}

extension CameraAuthorizationStatus {
    init(avAuthorizationStatus: AVAuthorizationStatus) {
        switch avAuthorizationStatus {
        case .authorized:
            self = .authorized
        case .denied:
            self = .denied
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        @unknown default:
            Logger.application.warning(
                "Unhandled AVAuthorizationStatus detected: \(String(describing: avAuthorizationStatus))"
            )
            self = .denied
        }
    }
}
