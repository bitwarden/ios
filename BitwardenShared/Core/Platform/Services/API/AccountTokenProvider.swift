import BitwardenKit
import Foundation
import Networking

// MARK: - AccountTokenProvider

/// A more specific `TokenProvider` protocol to use and ease testing.
protocol AccountTokenProvider: TokenProvider {
    /// Sets the delegate to use in this token provider.
    /// - Parameter delegate: The delegate to use.
    func setDelegate(delegate: AccountTokenProviderDelegate) async
}

// MARK: - DefaultAccountTokenProvider

/// A `TokenProvider` that gets the access token for the current account and can refresh it when
/// necessary.
///
actor DefaultAccountTokenProvider: AccountTokenProvider {
    // MARK: Properties

    /// The delegate to use for specific operations on the token provider.
    private weak var accountTokenProviderDelegate: AccountTokenProviderDelegate?

    /// The service used to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The `HTTPService` used to make the API call to refresh the access token.
    private let httpService: HTTPService

    /// The task associated with refreshing the token, if one is in progress.
    private(set) var refreshTask: Task<String, Error>?

    /// The service used to manage account state.
    private let stateService: StateService

    /// The service used to get the present time.
    private let timeProvider: TimeProvider

    /// The `TokenService` used to get the current tokens from.
    private let tokenService: TokenService

    // MARK: Initialization

    /// Initialize an `AccountTokenProvider`.
    ///
    /// - Parameters:
    ///   - httpService: The service used to make the API call to refresh the access token.
    ///   - timeProvider: The service used to get the present time.
    ///   - tokenService: The service used to get the current tokens from.
    ///   - errorReporter: The service used to report non-fatal errors.
    ///   - stateService: The service used to manage account state.
    ///
    init(
        httpService: HTTPService,
        timeProvider: TimeProvider = CurrentTime(),
        tokenService: TokenService,
        errorReporter: ErrorReporter,
        stateService: StateService,
    ) {
        self.httpService = httpService
        self.timeProvider = timeProvider
        self.tokenService = tokenService
        self.errorReporter = errorReporter
        self.stateService = stateService
    }

    // MARK: Methods

    func getToken() async throws -> String {
        if let refreshTask {
            // If there's a refresh in progress, wait for it to complete and return the refreshed
            // access token.
            return try await refreshTask.value
        }

        let token = try await tokenService.getAccessToken()
        if await shouldRefresh(accessToken: token) {
            return try await refreshToken()
        } else {
            return token
        }
    }

    func refreshToken() async throws -> String {
        if let refreshTask {
            // If there's a refresh in progress, wait for it to complete rather than triggering
            // another refresh.
            return try await refreshTask.value
        }

        let refreshTask = Task {
            defer { self.refreshTask = nil }

            do {
                // Capture userId BEFORE refresh
                let userIdBefore = try await stateService.getActiveAccountId()

                let refreshToken = try await tokenService.getRefreshToken()
                let response = try await httpService.send(
                    IdentityTokenRefreshRequest(refreshToken: refreshToken),
                )
                let expirationDate = timeProvider.presentTime.addingTimeInterval(TimeInterval(response.expiresIn))

                try await tokenService.setTokens(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken,
                    expirationDate: expirationDate,
                )

                // Capture userId AFTER refresh
                let userIdAfter = try await stateService.getActiveAccountId()

                // Detect race condition
                if userIdBefore != userIdAfter {
                    let error = TokenRefreshRaceConditionError(
                        userIdBefore: userIdBefore,
                        userIdAfter: userIdAfter,
                    )
                    errorReporter.log(error: error)
                }

                return response.accessToken
            } catch {
                if let accountTokenProviderDelegate {
                    try await accountTokenProviderDelegate.onRefreshTokenError(error: error)
                }
                throw error
            }
        }
        self.refreshTask = refreshTask

        return try await refreshTask.value
    }

    func setDelegate(delegate: AccountTokenProviderDelegate) async {
        accountTokenProviderDelegate = delegate
    }

    // MARK: Private

    /// Returns whether the access token needs to be refreshed based on the last stored access token
    /// expiration date. This is used to preemptively refresh the token prior to its expiration.
    ///
    /// - Parameter accessToken: The access token to determine whether it needs to be refreshed.
    /// - Returns: Whether the access token needs to be refreshed.
    ///
    private func shouldRefresh(accessToken: String) async -> Bool {
        guard let expirationDate = try? await tokenService.getAccessTokenExpirationDate() else {
            // If there's no stored expiration date, don't preemptively refresh the token.
            return false
        }

        let refreshThreshold = timeProvider.presentTime.addingTimeInterval(Constants.tokenRefreshThreshold)
        return expirationDate <= refreshThreshold
    }
}

/// Delegate to be used by the `AccountTokenProvider`.
protocol AccountTokenProviderDelegate: AnyObject {
    /// Callback to be used when an error is thrown when refreshing the access token.
    /// - Parameter error: `Error` thrown.
    func onRefreshTokenError(error: Error) async throws
}
