import AVFoundation
import Combine
import Foundation

// MARK: - CameraService

/// A service that is used to manage camera access and use for the user.
///
protocol CameraService: AnyObject {
    /// Checks the current camera authorization status without requesting authorization.
    ///
    /// This method provides a synchronous alternative to `checkStatusOrRequestCameraAuthorization()` for
    /// when we only need to determine the current status without requesting authorization.
    ///
    /// - Returns: The current `CameraAuthorizationStatus` of the app.
    ///
    func checkStatus() -> CameraAuthorizationStatus

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

    /// Retrieves the publisher for scan results when scanning QR codes.
    ///
    /// - Returns: An `AnyPublisher` that emits a`ScanResult` model.
    ///
    func getScanResultPublisher() -> AsyncPublisher<AnyPublisher<ScanResult?, Never>>

    /// Starts the camera session for QR code scanning and returns a publisher for scan results.
    ///
    /// This method initializes and starts the camera session.
    /// It returns a new `AVCaptureSession` used to scan QR codes.
    ///
    /// - Throws: An error if the camera session cannot be started.
    /// - Returns: A new `AVCaptureSession` for video/camera.
    ///
    func startCameraSession() async throws -> AVCaptureSession

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

// MARK: - DefaultCameraAuthorizationService

extension DefaultCameraService: CameraService {
    func checkStatus() -> CameraAuthorizationStatus {
        CameraAuthorizationStatus(
            avAuthorizationStatus: AVCaptureDevice.authorizationStatus(for: .video),
        )
    }

    func checkStatusOrRequestCameraAuthorization() async -> CameraAuthorizationStatus {
        let status = checkStatus()

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
            position: .unspecified,
        ).devices

        return !videoDevices.isEmpty
    }

    func getScanResultPublisher() -> AsyncPublisher<AnyPublisher<ScanResult?, Never>> {
        scanResultsSubject = .init(nil)
        return scanResultsSubject
            .eraseToAnyPublisher()
            .values
    }

    func startCameraSession() async throws -> AVCaptureSession {
        let status = await checkStatusOrRequestCameraAuthorization()
        guard case .authorized = status,
              let videoDevice = AVCaptureDevice.default(for: .video) else {
            throw CameraServiceError.unableToStartCaptureSession
        }
        let avCaptureSession = AVCaptureSession()
        cameraSession = avCaptureSession
        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        if avCaptureSession.canAddInput(videoInput) {
            avCaptureSession.addInput(videoInput)
        }
        if avCaptureSession.canAddOutput(metadataOutput) {
            avCaptureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            throw CameraServiceError.unableToStartScanning
        }
        DispatchQueue.global(qos: .userInitiated).async {
            avCaptureSession.startRunning()
        }
        scanResultsSubject = .init(nil)

        return avCaptureSession
    }

    func stopCameraSession() {
        guard let cameraSession else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            cameraSession.outputs.forEach { output in
                cameraSession.removeOutput(output)
            }
            cameraSession.stopRunning()
            self?.cameraSession = nil
        }
    }
}

// MARK: AVCaptureMetadataOutputObjectsDelegate

extension DefaultCameraService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection,
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
