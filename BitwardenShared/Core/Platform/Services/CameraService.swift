import AVFoundation
import Combine
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
    func getCameraSession() async -> AVCaptureSession?

    /// Starts the camera session for QR code scanning and returns a publisher for scan results.
    ///
    /// This method initializes and starts the camera session.
    /// It returns an `AnyPublisher` that emits a`ScanResult` model,
    ///  Non nil if the session scanned a code.
    ///
    /// - Throws: An error if the camera session cannot be started.
    /// - Returns: An `AnyPublisher` that emits a `ScanResult` model.
    ///
    func startCameraSession() throws -> AsyncPublisher<AnyPublisher<ScanResult?, Never>>

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
    case unableToStartScanning
}

/// The default `CameraService` type for the application
///
class DefaultCameraService: NSObject {
    // MARK: Private Properties

    /// The camera session in use.
    private var cameraSession: AVCaptureSession?

    /// A subject containing an array of scan results.
    private var scanResultsSubject = CurrentValueSubject<ScanResult?, Never>(nil)

    /// The output of the camera session.
    private let metadataOutput = AVCaptureMetadataOutput()

    // MARK: Private Methods

    /// Function to call when a scan result is found
    private func publishScanResult(_ result: ScanResult) {
        scanResultsSubject.send(result)
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

// MARK: - DefaultCamerAuthorizationService

extension DefaultCameraService: CameraService {
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

    func getCameraSession() async -> AVCaptureSession? {
        let status = await checkStatusOrRequestCameraAuthorization()
        guard case .authorized = status else {
            cameraSession = nil
            return nil
        }
        if cameraSession == nil {
            cameraSession = AVCaptureSession()
        }

        return cameraSession
    }

    func startCameraSession() throws -> AsyncPublisher<AnyPublisher<ScanResult?, Never>> {
        guard let cameraSession,
              let videoDevice = AVCaptureDevice.default(for: .video) else {
            throw CameraServiceError.unableToStartCaptureSession
        }
        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        if cameraSession.canAddInput(videoInput) {
            cameraSession.addInput(videoInput)
        }
        if cameraSession.canAddOutput(metadataOutput) {
            cameraSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            throw CameraServiceError.unableToStartScanning
        }
        DispatchQueue.global(qos: .userInitiated).async {
            cameraSession.startRunning()
        }

        return scanResultsSubject
            .eraseToAnyPublisher()
            .values
    }

    func stopCameraSession() {
        guard let cameraSession else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            cameraSession.stopRunning()
        }
    }
}

// MARK: AVCaptureMetadataOutputObjectsDelegate

extension DefaultCameraService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        for metadata in metadataObjects {
            if let readableObject = metadata as? AVMetadataMachineReadableCodeObject,
               let stringValue = readableObject.stringValue,
               readableObject.type == .qr {
                let scanResult = ScanResult(content: stringValue, codeType: readableObject.type)
                publishScanResult(scanResult)
            }
        }
    }
}
