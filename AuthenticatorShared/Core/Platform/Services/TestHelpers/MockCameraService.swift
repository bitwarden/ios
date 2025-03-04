import AVFoundation
import Combine

@testable import AuthenticatorShared

class MockCameraService: CameraService {
    typealias ScanPublisher = CurrentValueSubject<AuthenticatorShared.ScanResult?, Never>

    var cameraAuthorizationStatus: CameraAuthorizationStatus = .notDetermined
    var deviceHasCamera: Bool = true
    var didStart: Bool = false
    var didStop: Bool = false
    var resultsPublisher = ScanPublisher(nil)
    var startResult: Result<AVCaptureSession, Error> = .failure(CameraServiceError.unableToStartCaptureSession)

    // MARK: CameraService

    func checkStatus() -> CameraAuthorizationStatus {
        cameraAuthorizationStatus
    }

    func checkStatusOrRequestCameraAuthorization() async -> CameraAuthorizationStatus {
        cameraAuthorizationStatus
    }

    func deviceSupportsCamera() -> Bool {
        deviceHasCamera
    }

    func getScanResultPublisher() -> AsyncPublisher<AnyPublisher<ScanResult?, Never>> {
        resultsPublisher
            .eraseToAnyPublisher()
            .values
    }

    func startCameraSession() throws -> AVCaptureSession {
        didStart = true
        return try startResult.get()
    }

    func stopCameraSession() {
        didStop = true
    }
}
