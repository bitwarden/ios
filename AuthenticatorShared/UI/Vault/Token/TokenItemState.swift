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
        case existing(cipherView: CipherView)

        /// The existing `CipherView` if the configuration is `existing`.
        var existingCipherView: CipherView? {
            guard case let .existing(cipherView) = self else { return nil }
            return cipherView
        }
    }

    // MARK: Properties

    /// The Add or Existing Configuration.
    let configuration: Configuration

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
    }

    init?(existing cipherView: CipherView) {
        guard let totp = cipherView.login?.totp else { return nil }
        self.init(
            configuration: .existing(cipherView: cipherView),
            name: cipherView.name,
            totpState: LoginTOTPState(totp)
        )
    }
}

extension TokenItemState: ViewTokenItemState {
    var authenticatorKey: String? {
        totpState.rawAuthenticatorKeyString
    }

    var cipher: BitwardenSdk.CipherView {
        switch configuration {
        case let .existing(cipherView: view):
            return view
        case .add:
            return newCipherView()
        }
    }

    var totpCode: TOTPCodeModel? {
        totpState.codeModel
    }
}

extension TokenItemState {
    /// Returns a `CipherView` based on the properties of the `TokenItemState`.
    ///
    func newCipherView(creationDate: Date = .now) -> CipherView {
        CipherView(
            id: nil,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            key: nil,
            name: name,
            notes: nil,
            type: .login,
            login: .init(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: totpState.rawAuthenticatorKeyString,
                autofillOnPageLoad: nil,
                fido2Credentials: nil
            ),
            identity: nil,
            card: nil,
            secureNote: nil,
            favorite: false,
            reprompt: .none,
            organizationUseTotp: false,
            edit: false,
            viewPassword: false,
            localData: nil,
            attachments: nil,
            fields: nil,
            passwordHistory: nil,
            creationDate: creationDate,
            deletedDate: nil,
            revisionDate: creationDate
        )
    }
}
