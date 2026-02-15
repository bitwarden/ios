import Foundation
import Networking

@testable import BitwardenShared

class MockTokenService: TokenService {
    var accessToken: String? = "ACCESS_TOKEN"
    var accessTokenExpirationDateResult: Result<Date?, Error> = .success(nil)
    var expirationDate: Date?
    var getIsExternalResult: Result<Bool, Error> = .success(false)
    var refreshToken: String? = "REFRESH_TOKEN"

    // Track which userId was used in explicit userId methods
    var getAccessTokenCalledWithUserId: String?
    var getRefreshTokenCalledWithUserId: String?
    var setTokensCalledWithUserId: String?
    var activeAccountId: String = "1"
    var accessTokenByUserId: [String: String] = [:]
    var refreshTokenByUserId: [String: String] = [:]

    func getAccessToken() async throws -> String {
        guard let accessToken else { throw StateServiceError.noActiveAccount }
        return accessToken
    }

    func getAccessToken(userId: String) async throws -> String {
        getAccessTokenCalledWithUserId = userId
        return accessTokenByUserId[userId] ?? accessToken ?? "ACCESS_TOKEN"
    }

    func getAccessTokenExpirationDate() async throws -> Date? {
        try accessTokenExpirationDateResult.get()
    }

    func getActiveAccountId() async throws -> String {
        if activeAccountId.isEmpty {
            throw StateServiceError.noActiveAccount
        }
        return activeAccountId
    }

    func getIsExternal() async throws -> Bool {
        try getIsExternalResult.get()
    }

    func getRefreshToken() async throws -> String {
        guard let refreshToken else { throw StateServiceError.noActiveAccount }
        return refreshToken
    }

    func getRefreshToken(userId: String) async throws -> String {
        getRefreshTokenCalledWithUserId = userId
        return refreshTokenByUserId[userId] ?? refreshToken ?? "REFRESH_TOKEN"
    }

    func setTokens(accessToken: String, refreshToken: String, expirationDate: Date) async {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expirationDate = expirationDate
    }

    func setTokens(accessToken: String, refreshToken: String, expirationDate: Date, userId: String) async {
        setTokensCalledWithUserId = userId
        accessTokenByUserId[userId] = accessToken
        refreshTokenByUserId[userId] = refreshToken
        self.expirationDate = expirationDate
        // Also update legacy properties for backward compatibility with existing tests
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
