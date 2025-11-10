/// An object that represents a session timeout policy
///
public struct SessionTimeoutPolicy {
    // MARK: Properties

    /// The action to perform on session timeout.
    public let timeoutAction: SessionTimeoutAction?

    /// An enumeration of session timeout types to choose from.
    public let timeoutType: SessionTimeoutType?

    /// An enumeration of session timeout values to choose from.
    public let timeoutValue: SessionTimeoutValue?

    // MARK: Initialization

    /// Initialize `EnvironmentURLData` with the specified URLs.
    ///
    /// - Parameters:
    ///   - api: The URL for the API.
    public init(
        timeoutAction: SessionTimeoutAction?,
        timeoutType: SessionTimeoutType?,
        timeoutValue: SessionTimeoutValue?,
    ) {
        self.timeoutAction = timeoutAction
        self.timeoutType = timeoutType
        self.timeoutValue = timeoutValue
    }
}
