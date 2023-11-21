@testable import BitwardenShared

class MockCameraAuthorizationService: CameraAuthorizationService {
    var cameraAuthorizationStatus: CameraAuthorizationStatus = .notDetermined

    // MARK: CameraAuthorizationService

    func checkStatusOrRequestCameraAuthorization() async -> CameraAuthorizationStatus {
        cameraAuthorizationStatus
    }
}
