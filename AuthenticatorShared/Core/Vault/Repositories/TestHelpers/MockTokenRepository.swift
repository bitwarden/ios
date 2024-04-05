import BitwardenSdk
import Combine
import Foundation

@testable import AuthenticatorShared

class MockTokenRepository: TokenRepository {
    // MARK: Properties

    var addTokenTokens = [Token]()
    var addTokenResult: Result<Void, Error> = .success(())

    var deletedToken = [String]()
    var deleteTokenResult: Result<Void, Error> = .success(())

    var fetchTokenId: String?
    var fetchTokenResult: Result<Token?, Error> = .success(nil)

    var refreshTOTPCodeResult: Result<TOTPCodeModel, Error> = .success(
        TOTPCodeModel(code: .base32Key, codeGenerationDate: .now, period: 30)
    )
    var refreshedTOTPKeyConfig: TOTPKeyModel?

    var tokenListSubject = CurrentValueSubject<[Token], Never>([])

    // MARK: Methods

    func addToken(_ token: Token) async throws {
        addTokenTokens.append(token)
        try addTokenResult.get()
    }

    func deleteToken(_ id: String) async throws {
        deletedToken.append(id)
        try deleteTokenResult.get()
    }

    func fetchToken(withId id: String) async throws -> Token? {
        fetchTokenId = id
        return try fetchTokenResult.get()
    }

    func refreshTotpCode(for key: TOTPKeyModel) async throws -> AuthenticatorShared.TOTPCodeModel {
        refreshedTOTPKeyConfig = key
        return try refreshTOTPCodeResult.get()
    }

    func tokenPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[AuthenticatorShared.Token], Never>> {
        tokenListSubject.eraseToAnyPublisher().values
    }
}
