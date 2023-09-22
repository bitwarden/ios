import Networking

/// A `TokenProvider` that gets the access token for the current account and can refresh it when
/// necessary.
///
actor AccountTokenProvider: TokenProvider {
    // MARK: Properties

    /// The `HTTPService` used to make the API call to refresh the access token.
    let httpService: HTTPService

    /// The task associated with refreshing the token, if one is in progress.
    private(set) var refreshTask: Task<String, Error>?

    /// The `TokenService` used to get the current tokens from.
    let tokenService: TokenService

    // MARK: Initialization

    /// Initialize an `AccountTokenProvider`.
    ///
    /// - Parameters:
    ///   - httpService: The service used to make the API call to refresh the access token.
    ///   - tokenService: The service used to get the current tokens from.
    ///
    init(
        httpService: HTTPService,
        tokenService: TokenService
    ) {
        self.tokenService = tokenService
        self.httpService = httpService
    }

    // MARK: Methods

    func getToken() async throws -> String {
        if let refreshTask {
            // If there's a refresh in progress, wait for it to complete and return the refreshed
            // access token.
            return try await refreshTask.value
        }

        return try await tokenService.getAccessToken()
    }

    func refreshToken() async throws {
        if let refreshTask {
            // If there's a refresh in progress, wait for it to complete rather than triggering
            // another refresh.
            _ = try await refreshTask.value
            return
        }

        let refreshTask = Task {
            defer { self.refreshTask = nil }

            let refreshToken = try await tokenService.getRefreshToken()
            let response = try await httpService.send(
                IdentityTokenRefreshRequest(refreshToken: refreshToken)
            )
            await tokenService.setTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )

            return response.accessToken
        }
        self.refreshTask = refreshTask

        _ = try await refreshTask.value
    }
}
