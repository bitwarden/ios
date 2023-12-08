import BitwardenSdk
import Foundation

// MARK: - ViewItemState

/// The state of a `ViewItemProcessor`.
struct ViewItemState: Equatable {
    // MARK: Properties

    /// The current state. If this state is not `.loading`, this value will contain an associated value with the
    /// appropriate internal state.
    var loadingState: LoadingState<CipherItemState> = .loading

    /// A flag indicating if the master password is required before interacting with this item.
    var isMasterPasswordRequired: Bool {
        get {
            switch loadingState {
            case let .data(state):
                state.isMasterPasswordRePromptOn
            case .loading:
                false
            }
        }
        set {
            switch loadingState {
            case var .data(state):
                state.isMasterPasswordRePromptOn = newValue
                loadingState = .data(state)
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
        case .login, .secureNote:
            guard let cipherItemState = CipherItemState(existing: cipherView) else { return nil }
            self.init(loadingState: .data(cipherItemState))
        default:
            return nil
        }
    }
}
