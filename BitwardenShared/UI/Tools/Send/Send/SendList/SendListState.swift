import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - SendListState

/// An object that defines the current state of a `SendListView`.
///
struct SendListState: Sendable {
    /// The info URL to open.
    var infoUrl: URL?

    /// Is the view searching.
    var isSearching: Bool = false

    /// Whether sends are disabled via a policy.
    var isSendDisabled = false

    /// A flag indicating if the info button should be hidden.
    var isInfoButtonHidden: Bool { type != nil }

    /// The loading state of the send list screen.
    var loadingState: LoadingState<[SendListSection]> = .loading(nil)

    /// The navigation title for this screen.
    var navigationTitle: String { type?.localizedName ?? Localizations.send }

    /// The single Send type the user is restricted to by policy, or `nil` if both types are
    /// allowed. When set, the add-Send entry points open this type directly (bypassing the
    /// text/file chooser) and the "Types" filter section is hidden.
    var restrictedSendType: SendType?

    /// The text that the user is currently searching for.
    var searchText: String = ""

    /// An array of results matching the ``searchText``.
    var searchResults: [SendListItem] = []

    /// Whether the "Upgraded to Premium" action card should be shown.
    var shouldShowUpgradedToPremiumActionCard: Bool = false

    /// A toast message to show in the view.
    var toast: Toast?

    /// The type of sends to focus on in this list, if there is one. If `nil`, all Sends related
    /// information should be displayed.
    var type: SendType?

    /// The URL to open externally (e.g. learn more about Premium).
    var url: URL?
}
