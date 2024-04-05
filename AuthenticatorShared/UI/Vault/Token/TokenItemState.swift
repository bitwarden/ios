import BitwardenSdk
import Foundation

// MARK: - TokenState

/// An object that defines the current state of any view interacting with a token.
///
struct TokenItemState: Equatable {
    // MARK: Types

    /// An enum defining if the state is a new or existing token.
    enum Configuration: Equatable {
        /// We are creating a new token.
        case add

        /// We are viewing or editing an existing token.
        case existing(token: Token)

        /// The existing `CipherView` if the configuration is `existing`.
        var existingToken: Token? {
            guard case let .existing(token) = self else { return nil }
            return token
        }
    }

    // MARK: Properties

    /// The account of the token
    var account: String

    /// The Add or Existing Configuration.
    let configuration: Configuration

    /// A flag indicating if the key field is visible
    var isKeyVisible: Bool = false

    /// The issuer of the token
    var issuer: String

    /// The name of this item.
    var name: String

    /// A toast for views
    var toast: Toast?

    /// The TOTP key/code state.
    var totpState: LoginTOTPState

    // MARK: Initialization

    init(
        configuration: Configuration,
        name: String,
        totpState: LoginTOTPState
    ) {
        self.configuration = configuration
        self.name = name
        self.totpState = totpState
        account = "Fixme"
        issuer = "Fixme"
    }

    init?(existing token: Token) {
        self.init(
            configuration: .existing(token: token),
            name: token.name,
            totpState: LoginTOTPState(token.key.base32Key)
        )
    }
}

extension TokenItemState: EditTokenState {
    var editState: EditTokenState {
        self
    }
}

extension TokenItemState: ViewTokenItemState {
    var authenticatorKey: String? {
        totpState.rawAuthenticatorKeyString
    }

    var token: Token {
        switch configuration {
        case let .existing(token):
            return token
        case .add:
            return newToken()
        }
    }

    var totpCode: TOTPCodeModel? {
        totpState.codeModel
    }
}

extension TokenItemState {
    /// Returns a `Token` based on the properties of the `TokenItemState`.
    ///
    func newToken() -> Token {
        Token(name: name, authenticatorKey: totpState.rawAuthenticatorKeyString!)!
    }
}
