import BitwardenSdk
import Combine
import Foundation

/// A protocol for a `TokenReposity` which manages access to the data layer for tokens
///
public protocol TokenRepository: AnyObject {
    // MARK: Data Methods

    func addToken(_ token: Token) async throws

    func deleteToken(_ id: String) async throws

    func fetchToken(withId id: String) async throws -> Token?

    func refreshTotpCode(for key: TOTPKeyModel) async throws -> TOTPCodeModel

    // MARK: Publishers

    func tokenPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[Token], Never>>
}

class DefaultTokenRepository {
    // MARK: Properties

    /// The service to communicate with the SDK for encryption/decryption tasks.
    private let clientVault: ClientVaultService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used to get the present time.
    private let timeProvider: TimeProvider

    @Published var tokens: [Token] = [
        Token(name: "Amazon", authenticatorKey: "amazon")!,
    ]

    // MARK: Initialization

    /// Initialize a `DefaultTokenRepository`.
    ///
    /// - Parameters:
    ///   - clientVault: The service to communicate with the SDK for encryption/decryption tasks.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - timeProvider: The service used to get the present time.
    ///
    init(
        clientVault: ClientVaultService,
        errorReporter: ErrorReporter,
        timeProvider: TimeProvider
    ) {
        self.clientVault = clientVault
        self.errorReporter = errorReporter
        self.timeProvider = timeProvider
    }
}

extension DefaultTokenRepository: TokenRepository {
    // MARK: Data Methods

    func addToken(_ token: Token) async throws {
        tokens.append(token)
    }

    func deleteToken(_ id: String) async throws {
        tokens.removeAll { $0.id == id }
    }

    func fetchToken(withId id: String) async throws -> Token? {
        tokens.first { $0.id == id }
    }

    func refreshTotpCode(for key: TOTPKeyModel) async throws -> TOTPCodeModel {
        try await clientVault.generateTOTPCode(
            for: key.rawAuthenticatorKey,
            date: timeProvider.presentTime
        )
    }

    func tokenPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[Token], Never>> {
        tokens.publisher
            .collect()
            .eraseToAnyPublisher()
            .values
    }
}
