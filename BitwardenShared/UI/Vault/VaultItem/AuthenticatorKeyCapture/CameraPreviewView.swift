import AVFoundation
import SwiftUI
import UIKit

// MARK: - CameraPreviewView

/// A SwiftUI wrapper around `AVCaptureVideoPreviewLayer` and an `AVCaptureSession`.
///
public struct CameraPreviewView {
    // MARK: VideoPreviewView

    /// The UIView holding the `AVCaptureVideoPreviewLayer`.
    public class VideoPreviewView: UIView {
        /// The layerClass, overridden to be an `AVCaptureVideoPreviewLayer`.
        override public class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        /// The `UIView.layer` cast as `AVCaptureVideoPreviewLayer`.
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer // swiftlint:disable:this force_cast
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupOrientationObserver()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupOrientationObserver()
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        /// Configures observation of device orientation changes.
        ///     Changes trigger a call to `handleOrientationChange`.
        ///
        private func setupOrientationObserver() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleOrientationChange),
                name: UIDevice.orientationDidChangeNotification,
                object: nil,
            )
        }

        /// An `@objc` function to pass observations from `setupOrientationObserver`
        ///   to `adjustVideoOrientation`.
        ///
        @objc
        private func handleOrientationChange() {
            adjustVideoOrientation()
        }

        /// Adjusts the orientation of the video preview layer based on device orientation changes.
        ///     Currently supports `.landscapeLeft`, `.landscapeRight`, & `.portrait`
        ///
        private func adjustVideoOrientation() {
            DispatchQueue.main.async {
                switch UIDevice.current.orientation {
                case .landscapeLeft:
                    self.videoPreviewLayer.connection?.videoOrientation = .landscapeRight
                case .landscapeRight:
                    self.videoPreviewLayer.connection?.videoOrientation = .landscapeLeft
                case .portrait:
                    self.videoPreviewLayer.connection?.videoOrientation = .portrait
                default:
                    break
                }
            }
        }
    }

    /// The `AVCaptureSession` backing the view.
    ///
    public let session: AVCaptureSession

    /// Create a new VideoPreviewView.
    ///
    /// - Parameter session: The `AVCaptureSession` allowing for camera access.
    ///
    public init(session: AVCaptureSession) {
        self.session = session
    }
}

// MARK: UIViewRepresentable

extension CameraPreviewView: UIViewRepresentable {
    public func makeUIView(context: Context) -> VideoPreviewView {
        let viewFinder = VideoPreviewView()
        viewFinder.backgroundColor = .black
        viewFinder.videoPreviewLayer.cornerRadius = 0
        viewFinder.videoPreviewLayer.session = session
        viewFinder.videoPreviewLayer.videoGravity = .resizeAspectFill
        viewFinder.contentMode = .scaleAspectFill
        return viewFinder
    }

    public func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}
