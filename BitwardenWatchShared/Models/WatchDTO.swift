import Foundation

// MARK: - WatchDTO

/// The structure of the data used to communicate between the watch and the main app.
///
public struct WatchDTO: Codable {
    // MARK: Properties

    /// The state of the watch app.
    public var state: BWState

    /// The list of ciphers to display.
    public var ciphers: [CipherDTO]?

    /// The user data.
    public var userData: UserDTO?

    /// The urls to use.
    public var environmentData: EnvironmentUrlDTO?

    // MARK: Initialization

    /// Initializes a `WatchDTO`.
    ///
    /// - Parameters:
    ///   - state: The state of the watch app.
    ///   - ciphers: The list of ciphers to display.
    ///   - userData: The user data.
    ///   - environmentData: The urls to use.
    ///
    public init(
        state: BWState,
        ciphers: [CipherDTO]? = nil,
        userData: UserDTO? = nil,
        environmentData: EnvironmentUrlDTO? = nil
    ) {
        self.state = state
        self.ciphers = ciphers
        self.userData = userData
        self.environmentData = environmentData
    }
}
