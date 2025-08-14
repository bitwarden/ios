import BitwardenResources
import Foundation

// MARK: - VaultGroupState

/// The state of a `VaultGroupView`.
struct VaultGroupState: Equatable, Sendable {
    // MARK: Types

    /// The type of button to display in the view to add a new item. This is used for both the empty
    /// state new item button and the floating action button.
    ///
    enum NewItemButtonType: Equatable {
        /// The standard button which performs an action on tap.
        case button

        /// A button which displays a menu.
        case menu
    }

    // MARK: Properties

    /// The title of the add item button.
    var addItemButtonTitle: String {
        switch group {
        case .card:
            return Localizations.newCard
        case .collection, .folder:
            return Localizations.newItem
        case .identity:
            return Localizations.newIdentity
        case .login:
            return Localizations.newLogin
        case .secureNote:
            return Localizations.newNote
        default:
            return Localizations.newItem
        }
    }

    /// Whether the vault filter can be shown.
    var canShowVaultFilter = true

    /// Whether there is data for the vault group.
    var emptyData: Bool {
        loadingState.data.isEmptyOrNil
    }

    /// The type of the new item button in the empty state and FAB to display based on which group
    /// type is shown.
    var newItemButtonType: NewItemButtonType? {
        if let cipherType = CipherType(group: group), !itemTypesUserCanCreate.contains(cipherType) {
            return nil
        }

        switch group {
        case .card, .identity, .login, .secureNote:
            return .button
        case .collection, .folder, .noFolder:
            return .menu
        case .sshKey, .totp, .trash:
            return nil
        }
    }

    /// The `VaultListGroup` being displayed.
    var group: VaultListGroup = .login

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// List of available item type for creation.
    var itemTypesUserCanCreate: [CipherType] = CipherType.canCreateCases

    /// Whether the policy is enforced to disable personal vault ownership.
    var isPersonalOwnershipDisabled: Bool = false

    /// Is the view searching.
    var isSearching: Bool = false

    /// The current loading state.
    var loadingState: LoadingState<[VaultListSection]> = .loading(nil)

    /// The string to use in the empty view.
    var noItemsString: String {
        switch group {
        case .card:
            return Localizations.thereAreNoCardsInYourVault
        case .collection:
            return Localizations.noItemsCollection
        case .folder:
            return Localizations.noItemsFolder
        case .identity:
            return Localizations.thereAreNoIdentitiesInYourVault
        case .login:
            return Localizations.thereAreNoLoginsInYourVault
        case .secureNote:
            return Localizations.thereAreNoNotesInYourVault
        case .sshKey:
            return Localizations.thereAreNoSSHKeysInYourVault
        case .trash:
            return Localizations.noItemsTrash
        default:
            return Localizations.noItems
        }
    }

    /// The list of organizations the user is a member of.
    var organizations = [Organization]()

    /// An array of results matching the `searchText`.
    var searchResults = [VaultListItem]()

    /// The text in the search bar.
    var searchText = ""

    /// The search vault filter used to display a single or all vaults for the user.
    var searchVaultFilterType = VaultFilterType.allVaults

    /// Whether to show the special web icons.
    var showWebIcons = true

    /// A toast message to show in the view.
    var toast: Toast?

    /// The url to open in the device's web browser.
    var url: URL?

    /// The state for showing the vault filter.
    var vaultFilterState: SearchVaultFilterRowState {
        SearchVaultFilterRowState(
            canShowVaultFilter: canShowVaultFilter,
            isPersonalOwnershipDisabled: isPersonalOwnershipDisabled,
            organizations: organizations,
            searchVaultFilterType: searchVaultFilterType
        )
    }

    /// The vault filter used to display a single or all vaults for the user.
    let vaultFilterType: VaultFilterType
}
