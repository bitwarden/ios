import BitwardenSdk
import Foundation

// MARK: - ViewItemState

/// The state of a `ViewItemProcessor`.
struct ViewItemState: Equatable {
    // MARK: Types

    /// An enumeration of the possible values of this state.
    enum ItemTypeState: Equatable {
        /// The processor is currently loading.
        case loading

        /// A login item's representative state.
        case login(ViewLoginItemState)
    }

    // MARK: Properties

    /// The current state. If this state is not `.loading`, this value will contain an associated value with the
    /// appropriate internal state.
    var typeState: ItemTypeState = .loading
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
            guard let loginItem = cipherView.login else { return nil }
            self.init(
                typeState: .login(
                    ViewLoginItemState(
                        customFields: cipherView.fields ?? [],
                        folder: cipherView.folderId,
                        isPasswordVisible: cipherView.viewPassword,
                        name: cipherView.name,
                        notes: cipherView.notes,
                        password: loginItem.password,
                        updatedDate: cipherView.revisionDate,
                        uris: loginItem.uris ?? [],
                        username: loginItem.username
                    )
                )
            )
        default:
            return nil
        }
    }
}
