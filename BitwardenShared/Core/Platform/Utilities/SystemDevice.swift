import UIKit

/// A protocol for an object that can provide information for the current device.
///
protocol SystemDevice {
    /// The model of the device e.g. "iPhone" or "iPad".
    var model: String { get }

    /// The name of the operating system on the device e.g. "iOS".
    var systemName: String { get }

    /// The version of the operating system on the device e.g. "17.0".
    var systemVersion: String { get }
}

extension UIDevice: SystemDevice {}
