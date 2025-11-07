public protocol ActiveAccountIDProvider: AnyObject {
    /// Gets the active account id.
    ///
    /// - Returns: The active user account id.
    ///
    func getActiveAccountId() async throws -> String
}
