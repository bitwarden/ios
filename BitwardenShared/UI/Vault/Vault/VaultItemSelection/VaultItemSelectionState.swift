import BitwardenSdk
import Foundation

// MARK: - VaultItemSelectionState

/// An object that defines the current state of a `VaultItemSelectionView`.
///
struct VaultItemSelectionState: Equatable {
    // MARK: Properties

    /// The base url used to fetch icons.
    let iconBaseURL: URL?

    /// The parsed OTP key used to find matching ciphers to add the key to.
    let otpAuthModel: OTPAuthModel

    /// The user's current account profile state and alternative accounts.
    var profileSwitcherState: ProfileSwitcherState = .empty(shouldAlwaysHideAddAccount: true)

    /// The list of vault list items matching the `searchText`.
    var searchResults = [VaultListItem]()

    /// The text that the user is currently searching for.
    var searchText = ""

    /// Whether the no search results view should be shown.
    var showNoResults = false

    /// Whether to show the special web icons.
    var showWebIcons = true

    /// A toast message to show in the view.
    var toast: Toast?

    /// The url to open in the device's web browser.
    var url: URL?

    /// The list of sections to display for matching vault items.
    var vaultListSections = [VaultListSection]()

    // MARK: Computed Properties

    /// The search term used to find ciphers that match the OTP key.
    var ciphersMatchingName: String? {
        otpAuthModel.issuer ?? otpAuthModel.accountName
    }
}
