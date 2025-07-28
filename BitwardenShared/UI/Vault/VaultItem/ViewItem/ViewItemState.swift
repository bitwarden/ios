import BitwardenResources
@preconcurrency import BitwardenSdk
import Foundation

// MARK: - ViewItemState

/// The state of a `ViewItemProcessor`.
struct ViewItemState: Equatable, Sendable {
    // MARK: Properties

    /// A flag indicating if the current cipher can be cloned.
    var canClone: Bool {
        switch loadingState {
        case let .data(state):
            state.cipher.organizationId == nil
        case .error, .loading:
            false
        }
    }

    /// Whether the cipher can be edited.
    var canEdit: Bool {
        loadingState.data?.cipher.deletedDate == nil
    }

    /// The current state. If this state is not `.loading`, this value will contain an associated value with the
    /// appropriate internal state.
    var loadingState: LoadingState<CipherItemState> = .loading(nil)

    /// A flag indicating if the user has premium features.
    var hasPremiumFeatures = false

    /// The view's navigation title.
    var navigationTitle: String {
        guard let item = loadingState.data else { return "" }
        return switch item.type {
        case .card: Localizations.viewCard
        case .identity: Localizations.viewIdentity
        case .login: Localizations.viewLogin
        case .secureNote: Localizations.viewNote
        case .sshKey: Localizations.viewSSHKey
        }
    }

    /// The password history of the item.
    var passwordHistory: [PasswordHistoryView]?

    /// A toast message to show in the view.
    var toast: Toast?
}

extension ViewItemState {
    // MARK: Initialization

    /// Creates a new `ViewItemState` from a provided `CipherView` from the vault.
    ///
    /// - Parameters:
    ///   - cipherView: The `CipherView` to create this state with.
    ///   - hasPremium: Does the account have premium features.
    ///   - iconBaseURL: The base url used to fetch icons.
    ///
    init?(
        cipherView: CipherView,
        hasPremium: Bool,
        iconBaseURL: URL?
    ) {
        guard var cipherItemState = CipherItemState(
            existing: cipherView,
            hasPremium: hasPremium,
            iconBaseURL: iconBaseURL
        ) else { return nil }
        self.init(loadingState: .data(cipherItemState))
        hasPremiumFeatures = cipherItemState.accountHasPremium
        passwordHistory = cipherView.passwordHistory
    }
}
