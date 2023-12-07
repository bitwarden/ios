import BitwardenSdk
import Foundation

// MARK: - ViewLoginItemState

/// The state for viewing a login item.
struct ViewLoginItemState: Equatable {
    // MARK: Properties

    /// The Cipher underpinning the state
    var cipher: CipherView

    /// The custome fields.
    var customFields: [CustomFieldState]

    /// A flag indicating if master password re-prompt is required.
    var isMasterPasswordRePromptOn: Bool

    /// The login item state.
    var loginState: LoginItemState

    /// The name of this item.
    var name: String

    /// The notes of this item.
    var notes: String

    /// When this item was last updated.
    var updatedDate: Date

    /// What cipher type this item is.
    let type: CipherType = .login
}

extension CipherView {
    var customFields: [CustomFieldState] {
        fields?.map(CustomFieldState.init) ?? []
    }

    var shouldRequirePasswordPrompt: Bool {
        switch reprompt {
        case .password: true
        case .none: false
        }
    }

    func loginItemState(showPassword: Bool = false) -> LoginItemState {
        .init(
            isPasswordVisible: showPassword,
            password: login?.password ?? "",
            passwordUpdatedDate: login?.passwordRevisionDate,
            uris: login?.uris?.map { uriView in
                CipherLoginUriModel(loginUriView: uriView)
            } ?? [],
            username: login?.username ?? ""
        )
    }
}

extension BitwardenSdk.CipherType {
    var sharedType: BitwardenShared.CipherType {
        switch self {
        case .login:
            return .login
        case .secureNote:
            return .secureNote
        case .card:
            return .card
        case .identity:
            return .identity
        }
    }
}
