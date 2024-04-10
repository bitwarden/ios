import BitwardenSdk
import Foundation

// MARK: - ViewTokenState

/// A `Sendable` type used to describe the state of a `ViewTokenView`
struct ViewTokenState: Sendable {
    // MARK: Properties

    /// The current state. If this state is not `.loading`, this value will contain an associated value with the
    /// appropriate internal state.
    var loadingState: LoadingState<AuthenticatorItemState> = .loading(nil)

    /// A toast message to show in the view.
    var toast: Toast?
}

extension ViewTokenState {
    // MARK: Initialization

    /// Creates a new `ViewTokenState` from a provided `AuthenticatorItemView`.
    ///
    /// - Parameters:
    ///   - cipherView: The `CipherView` to create this state with.
    ///
    init?(authenticatorItemView: AuthenticatorItemView) {
        guard let authenticatorItemState = AuthenticatorItemState(
            existing: authenticatorItemView
        ) else { return nil }
        self.init(loadingState: .data(authenticatorItemState))
    }
}
