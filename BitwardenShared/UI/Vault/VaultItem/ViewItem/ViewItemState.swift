import BitwardenSdk
import Foundation

// MARK: - ViewItemState

/// The state of a `ViewItemProcessor`.
struct ViewItemState: Equatable {
    // MARK: Types

    /// An enumeration of the possible values of this state.
    enum ItemTypeState: Equatable {
        /// A login item's representative state.
        case login(LoginItemState)
    }

    // MARK: Properties

    /// The current state. If this state is not `.loading`, this value will contain an associated value with the
    /// appropriate internal state.
    var loadingState: LoadingState<ItemTypeState> = .loading
}

extension ViewItemState {
    // MARK: Initialization

    /// Creates a new `ViewItemState` from a provided `CipherView` from the vault.
    ///
    /// - Parameter cipherView: The `CipherView` to create this state with.
    ///
    init?(cipherView: CipherView) {
        switch cipherView.type {
        case .login:
            guard let loginItemState = LoginItemState(cipherView: cipherView) else { return nil }
            self.init(loadingState: .data(.login(loginItemState)))
        default:
            return nil
        }
    }
}

extension CipherView {
    func updatedView(with editState: AddEditItemState) -> CipherView {
        let properties = editState.properties
        return CipherView(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            name: properties.name,
            notes: properties.notes.nilIfEmpty,
            type: BitwardenSdk.CipherType(.login),
            login: BitwardenSdk.LoginView(
                username: properties.username.nilIfEmpty,
                password: properties.password.nilIfEmpty,
                passwordRevisionDate: login?.passwordRevisionDate,
                uris: login?.uris,
                totp: login?.totp,
                autofillOnPageLoad: login?.autofillOnPageLoad
            ),
            identity: identity,
            card: card,
            secureNote: secureNote,
            favorite: properties.isFavoriteOn,
            reprompt: properties.isMasterPasswordRePromptOn ? .password : .none,
            organizationUseTotp: false,
            edit: true,
            viewPassword: true,
            localData: localData,
            attachments: attachments,
            fields: fields,
            passwordHistory: passwordHistory,
            creationDate: creationDate,
            deletedDate: nil,
            revisionDate: revisionDate
        )
    }
}
