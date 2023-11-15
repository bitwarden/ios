@testable import BitwardenShared

class MockCameraAuthorizationService: CameraAuthorizationService {
    var requestCameraAuthorizationCalled = false
    var requestCameraAuthorizationResult: CameraAuthorizationStatus = .authorized

    // MARK: CameraAuthorizationService

    var cameraAuthorizationStatus: CameraAuthorizationStatus = .notDetermined

    func requestCameraAuthorization() async -> CameraAuthorizationStatus {
        requestCameraAuthorizationCalled = true
        return requestCameraAuthorizationResult
    }
}
