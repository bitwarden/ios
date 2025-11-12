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

    /// Initialize `SessionTimeoutPolicy` with the specified values.
    ///
    /// - Parameters:
    ///   - timeoutAction: The action to perform on session timeout.
    ///   - timeoutType: The type of session timeout.
    ///   - timeoutValue: The session timeout value.
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
