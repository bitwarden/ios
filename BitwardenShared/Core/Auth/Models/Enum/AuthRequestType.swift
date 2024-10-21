// MARK: - AuthRequestType

/// The type of auth request.
///
public enum AuthRequestType: Int, Codable, Sendable {
    /// Login with device request
    case authenticateAndUnlock = 0

    /// Admin approval request
    case adminApproval = 2
}
