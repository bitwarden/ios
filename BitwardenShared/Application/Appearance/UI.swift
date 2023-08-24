import Foundation
import UIKit

// swiftlint:disable type_name

/// Utility and factory methods for building out user interfaces.
///
public enum UI {
    // MARK: Utilities

    /// App-wide flag that allows disabling UI animations for testing.
    public static var animated = true

    #if DEBUG
    /// App-wide flag that allows overriding the OS level sizeCategory for testing.
    public static var sizeCategory: UIContentSizeCategory?
    #endif

    // MARK: Factories

    /// Returns the specified duration when `UI.animated` is `true`, or `0.0` when `UI.animated`
    /// is `false`.
    ///
    /// - Parameter duration: The animation `TimeInterval` when `UI.animation` is `true`.
    ///
    /// - Returns: The duration based on whether animations are disabled or not.
    ///
    public static func duration(_ duration: TimeInterval) -> TimeInterval {
        animated ? duration : 0.0
    }

    /// Returns a `DispatchTime` with the number of seconds added to `DispatchTime.now` when
    /// `UI.animation` is `true` or `DispatchTime.now` when `UI.animation` is `false`.
    ///
    /// - Parameter after: The number of seconds to add to `DispatchTime.now` when `UI.animation` is
    ///     `true`.
    ///
    /// - Returns: The `DispatchTime` with `after` seconds added to it if animations are enabled or
    ///     `DispatchTime.now` if not.
    ///
    public static func after(_ after: TimeInterval) -> DispatchTime {
        animated ? .now() + after : .now()
    }
}

// swiftlint:enable type_name
