import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

extension Data {
    /// Builds GIF data with the given number of frames, for use in tests.
    ///
    /// - Parameters:
    ///   - frameCount: The number of frames in the GIF.
    ///   - delayTime: The delay between frames, in seconds.
    /// - Returns: The GIF data, or `nil` if it couldn't be built.
    ///
    static func testGif(frameCount: Int, delayTime: Double = 0.05) -> Data? {
        guard let image = UIImage(systemName: "photo")?.cgImage else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.gif.identifier as CFString,
            frameCount,
            nil,
        ) else { return nil }
        let frameProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delayTime]]
        for _ in 0 ..< frameCount {
            CGImageDestinationAddImage(destination, image, frameProperties as CFDictionary)
        }
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
