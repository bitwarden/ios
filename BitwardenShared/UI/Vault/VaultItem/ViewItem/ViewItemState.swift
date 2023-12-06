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

    /// A flag indicating if the master password is required before interacting with this item.
    var isMasterPasswordRequired: Bool {
        get {
            switch loadingState {
            case let .data(value):
                switch value {
                case let .login(state):
                    state.properties.isMasterPasswordRePromptOn
                }
            case .loading:
                false
            }
        }
        set {
            switch loadingState {
            case let .data(value):
                switch value {
                case var .login(state):
                    state.properties.isMasterPasswordRePromptOn = newValue
                    loadingState = .data(.login(state))
                }
            case .loading:
                break
            }
        }
    }
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
