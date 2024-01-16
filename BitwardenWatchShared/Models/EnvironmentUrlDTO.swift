import Foundation

// MARK: - EnvironmentUrlDTO

/// The environment data used to communicate between the watch and the main app.
///
public struct EnvironmentUrlDTO: Codable {
    // MARK: Properties

    /// The base url.
    public var base: String?

    /// The url used for loading icons.
    public var icons: String?

    // MARK: Initialization

    /// Initializes a `EnvironmentUrlDTO`.
    ///
    /// - Parameters:
    ///   - base: The base url.
    ///   - icons: The url used for loading icons.
    ///
    public init(base: String? = nil, icons: String? = nil) {
        self.base = base
        self.icons = icons
    }
}
