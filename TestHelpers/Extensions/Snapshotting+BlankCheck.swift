import SnapshotTesting
import Testing
import UIKit
import XCTest

// MARK: - Snapshotting

extension Snapshotting where Format == UIImage {
    /// Returns a copy of this strategy that fails the test when a captured image is a single
    /// solid color.
    ///
    /// A single-color snapshot almost always means the capture failed (for example, Liquid Glass
    /// content that couldn't be drawn, or a view taller than the capture limit) or the view rendered
    /// nothing. swift-snapshot-testing would otherwise save it as a reference image, and the test
    /// would keep passing against it. To test that a view renders nothing, use a ViewInspector test.
    ///
    /// - Returns: A snapshot strategy that checks each captured image.
    ///
    func failingOnSingleColorImages() -> Snapshotting {
        Snapshotting(
            pathExtension: pathExtension,
            diffing: diffing,
            asyncSnapshot: { value in
                snapshot(value).map { image in
                    if image.isSingleColor {
                        recordSingleColorSnapshotFailure()
                    }
                    return image
                }
            },
        )
    }
}

// MARK: - UIImage

extension UIImage {
    /// Whether every pixel in the image is the same color.
    ///
    /// The image is drawn into an 8-bit sRGB bitmap at its point size, which normalizes the
    /// different pixel formats snapshots are saved in. Downscaling averages neighboring pixels, so
    /// any visible content still produces more than one color.
    ///
    var isSingleColor: Bool {
        guard let cgImage else { return false }
        let width = max(1, Int(size.width.rounded()))
        let height = max(1, Int(size.height.rounded()))
        var pixels = [UInt32](repeating: 0, count: width * height)
        let didDraw = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(
                      data: buffer.baseAddress,
                      width: width,
                      height: height,
                      bitsPerComponent: 8,
                      bytesPerRow: width * 4,
                      space: colorSpace,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue,
                  )
            else {
                return false
            }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard didDraw, let first = pixels.first else { return false }
        return pixels.allSatisfy { $0 == first }
    }
}

// MARK: - Private

/// Records a test failure for a single-color snapshot, in either Swift Testing or XCTest.
///
private func recordSingleColorSnapshotFailure() {
    let message = """
    Snapshot is a single solid color. The capture probably failed or the view rendered nothing. \
    To test that a view renders nothing, use a ViewInspector test instead of a snapshot.
    """
    if Test.current != nil {
        Issue.record(Comment(rawValue: message))
    } else {
        XCTFail(message)
    }
}
