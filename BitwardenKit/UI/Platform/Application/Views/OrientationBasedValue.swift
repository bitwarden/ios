import SwiftUI

// MARK: OrientationBasedDimension

/// An `OrientationBasedValue` encapsulates values that might be different
/// for rendering based on orientation, such as image size or space between text.
public struct OrientationBasedValue<T: Equatable & Sendable>: Equatable, Sendable {
    // MARK: Properties

    /// The dimension size in portrait mode.
    let portrait: T

    /// The dimension size in landscape mode.
    let landscape: T

    // MARK: Initialization

    /// Initializes an `OrientationBasedValue` that has different values in portrait and landscape.
    /// - Parameters:
    ///   - portrait: The value in portrait mode.
    ///   - landscape: The value in landscape mode.
    ///
    public init(portrait: T, landscape: T) {
        self.portrait = portrait
        self.landscape = landscape
    }

    /// Initializes an `OrientationBasedValue` that has the same value in both portrait and landscape.
    /// - Parameters:
    ///   - both: The value in both portrait and landscape mode.
    ///
    public init(both: T) {
        portrait = both
        landscape = both
    }

    // MARK: Functions

    /// Convenience function for getting the correct value based on the orientation.
    ///
    public func value(_ verticalSizeClass: UserInterfaceSizeClass) -> T {
        verticalSizeClass == .regular ? portrait : landscape
    }
}
