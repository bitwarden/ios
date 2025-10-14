import Foundation
import Networking

@testable import BitwardenShared

class MockTokenService: TokenService {
    var accessToken: String? = "ACCESS_TOKEN"
    var accessTokenExpirationDateResult: Result<Date?, Error> = .success(nil)
    var expirationDate: Date?
    var getIsExternalResult: Result<Bool, Error> = .success(false)
    var refreshToken: String? = "REFRESH_TOKEN"

    func getAccessToken() async throws -> String {
        guard let accessToken else { throw StateServiceError.noActiveAccount }
        return accessToken
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

    func setTokens(accessToken: String, refreshToken: String, expirationDate: Date) async {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expirationDate = expirationDate
    }
}
