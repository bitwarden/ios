import Foundation

// MARK: - DebugMenuFeatureFlag

/// A structure representing a feature flag in the debug menu, including its enabled state.
/// This is used to display and manage feature flags within the debug menu interface.
///
public struct DebugMenuFeatureFlag: Equatable, Identifiable, Sendable {
    /// A unique identifier for the feature flag, based on its raw value.
    public var id: String {
        feature.rawValue
    }

    /// The feature flag enum that this instance represents.
    public let feature: FeatureFlag

    /// A boolean value indicating whether the feature is enabled or not.
    public let isEnabled: Bool

    /// Initializes a `DebugMenuFeatureFlag`.
    ///
    /// - Parameters:
    ///   - feature: The feature flag enum that this instance represents.
    ///   - isEnabled: A boolean value indicating whether the feature is enabled or not.
    public init(feature: FeatureFlag, isEnabled: Bool) {
        self.feature = feature
        self.isEnabled = isEnabled
    }
}
