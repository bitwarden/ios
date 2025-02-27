import AVFoundation
import UIKit

/// A model that captures the data from a scanned QR Code.
///
public struct ScanResult: Equatable, Hashable {
    /// The string content encoded in the QR code.
    let content: String

    /// The type of code that was scanned (e.g., QR code, barcode).
    let codeType: AVMetadataObject.ObjectType
}
