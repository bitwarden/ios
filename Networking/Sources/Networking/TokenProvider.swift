/// A `TokenProvider` handles getting an access token and refreshing it when necessary.
///
public protocol TokenProvider {
    /// Gets the current access token.
    ///
    /// - Returns: The current access token.
    ///
    func getToken() async throws -> String

    /// Refreshes the access token by using the refresh token to acquire a new access token.
    ///
    func refreshToken() async throws
}
