import Foundation
import Networking

@testable import BitwardenShared

class MockTokenService: TokenService {
    var accessToken: String? = "ACCESS_TOKEN"
    var accessTokenExpirationDateResult: Result<Date?, Error> = .success(nil)
    var accessTokenThrowableError: (any Error)?
    var expirationDate: Date?
    var getIsExternalResult: Result<Bool, Error> = .success(false)
    var refreshToken: String? = "REFRESH_TOKEN"

    var accessTokenByUserId: [String: String] = [:]
    var getAccessTokenCalledWithUserId: String?
    var getRefreshTokenCalledWithUserId: String?
    var refreshTokenByUserId: [String: String] = [:]
    var setTokensCalledWithUserId: String?

    func getAccessToken() async throws -> String {
        if let accessTokenThrowableError { throw accessTokenThrowableError }
        guard let accessToken else { throw StateServiceError.noActiveAccount }
        return accessToken
    }

    func getAccessToken(userId: String) async throws -> String {
        getAccessTokenCalledWithUserId = userId
        if let accessTokenThrowableError { throw accessTokenThrowableError }
        return accessTokenByUserId[userId] ?? accessToken ?? "ACCESS_TOKEN"
    }

    func getAccessTokenExpirationDate() async throws -> Date? {
        try accessTokenExpirationDateResult.get()
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
