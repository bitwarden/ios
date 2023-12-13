import AVFoundation
import Combine

@testable import BitwardenShared

class MockCameraService: CameraService {
    typealias ScanPublisher = CurrentValueSubject<BitwardenShared.ScanResult?, Never>

    var cameraAuthorizationStatus: CameraAuthorizationStatus = .notDetermined
    var cameraSession: AVCaptureSession?
    var deviceHasCamera: Bool = true
    var didStart: Bool = false
    var didStop: Bool = false
    var startResult: Result<ScanPublisher, Error> = .success(ScanPublisher(nil))

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

    func startCameraSession() throws -> AsyncPublisher<AnyPublisher<BitwardenShared.ScanResult?, Never>> {
        didStart = true
        return try startResult.get()
            .eraseToAnyPublisher()
            .values
    }

    func stopCameraSession() {
        didStop = true
    }
}
