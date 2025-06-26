import Networking

// MARK: - AccountTokenProvider

/// A more specific `TokenProvider` protocol to use and ease testing.
protocol AccountTokenProvider: TokenProvider {
    /// Sets up the delegate to use in this token provider.
    /// - Parameter delegate: The delegate to use.
    func setupDelegate(delegate: AccountTokenProviderDelegate) async
}

// MARK: - DefaultAccountTokenProvider

/// A `TokenProvider` that gets the access token for the current account and can refresh it when
/// necessary.
///
actor DefaultAccountTokenProvider: AccountTokenProvider {
    // MARK: Properties

    /// The delegate to use for specific operations on the token provider.
    private weak var accountTokenProviderDelegate: AccountTokenProviderDelegate?

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

            do {
                let refreshToken = try await tokenService.getRefreshToken()
                let response = try await httpService.send(
                    IdentityTokenRefreshRequest(refreshToken: refreshToken)
                )
                try await tokenService.setTokens(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken
                )

                return response.accessToken
            } catch {
                if let accountTokenProviderDelegate {
                    try await accountTokenProviderDelegate.onRefreshTokenError(error: error)
                }
                throw error
            }
        }
        self.refreshTask = refreshTask

        _ = try await refreshTask.value
    }

    func setupDelegate(delegate: AccountTokenProviderDelegate) async {
        accountTokenProviderDelegate = delegate
    }
}

protocol AccountTokenProviderDelegate: AnyObject {
    func onRefreshTokenError(error: Error) async throws
}
