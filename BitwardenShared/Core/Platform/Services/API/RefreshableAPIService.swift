// MARK: - RefreshableAPIService

/// API service protocol to refresh tokens.
protocol RefreshableAPIService { // sourcery: AutoMockable
    /// Refreshes the access token by using the refresh token to acquire a new access token.
    ///
    func refreshAccessToken() async throws
}

extension APIService: RefreshableAPIService {
    func refreshAccessToken() async throws {
        _ = try await accountTokenProvider.refreshToken()
    }
}
