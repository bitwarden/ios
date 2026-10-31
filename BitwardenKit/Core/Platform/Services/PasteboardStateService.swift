// MARK: - PasteboardStateService

/// A protocol for a service that provides state management functionality around the pasteboard.
///
public protocol PasteboardStateService: AnyObject { // sourcery: AutoMockable
    /// Gets the Universal Clipboard setting for a user account.
    ///
    /// - Parameter userId: The user ID associated with the Universal Clipboard setting. Defaults to
    ///     the active account if `nil`.
    /// - Returns: A Boolean value indicating whether Universal Clipboard is allowed.
    ///
    func getAllowUniversalClipboard(userId: String?) async throws -> Bool

    /// Gets the clear clipboard value for an account.
    ///
    /// - Parameter userId: The user ID associated with the clear clipboard value. Defaults to the
    ///     active account if `nil`.
    /// - Returns: The time after which the clipboard should clear.
    ///
    func getClearClipboardValue(userId: String?) async throws -> ClearClipboardValue

    /// Sets the Universal Clipboard setting for a user account.
    ///
    /// - Parameters:
    ///   - allowUniversalClipboard: A Boolean value indicating whether Universal Clipboard should be allowed.
    ///   - userId: The user ID associated with the Universal Clipboard setting. Defaults to the
    ///     active account if `nil`.
    ///
    func setAllowUniversalClipboard(_ allowUniversalClipboard: Bool, userId: String?) async throws

    /// Sets the clear clipboard value for an account.
    ///
    /// - Parameters:
    ///   - clearClipboardValue: The time after which to clear the clipboard.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String?) async throws
}
