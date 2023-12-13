import AVFoundation

@testable import BitwardenShared

class MockCameraService: CameraService {
    var cameraAuthorizationStatus: CameraAuthorizationStatus = .notDetermined
    var cameraSession: AVCaptureSession?
    var deviceHasCamera: Bool = true
    var didStart: Bool = false
    var didStop: Bool = false
    var startResult: Result<Void, Error> = .success(())

    // MARK: CameraService

    func checkStatusOrRequestCameraAuthorization() async -> CameraAuthorizationStatus {
        cameraAuthorizationStatus
    }

    func deviceSupportsCamera() -> Bool {
        deviceHasCamera
    }

    func getCameraSession() -> AVCaptureSession? {
        cameraSession
    }

    func startCameraSession() throws {
        try startResult.get()
        didStart = true
    }

    func stopCameraSession() {
        didStop = true
    }
}
