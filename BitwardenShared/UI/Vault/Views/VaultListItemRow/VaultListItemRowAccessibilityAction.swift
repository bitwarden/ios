import BitwardenResources

// MARK: - VaultListItemRowAccessibilityAction

/// A VoiceOver custom accessibility action exposed on a `VaultListItemRowView`, listed in the
/// Actions rotor.
enum VaultListItemRowAccessibilityAction: Equatable {
    /// Performs a single more-options action directly on the item.
    case kind(MoreOptionsActionKind)

    /// Opens the full more-options sheet for the item.
    case moreOptions

    // MARK: Properties

    /// The effect dispatched when this action is activated.
    var effect: VaultListItemRowEffect {
        switch self {
        case let .kind(kind):
            .accessibilityMoreOptionsActionPressed(kind)
        case .moreOptions:
            .morePressed
        }
    }

    /// The name VoiceOver announces for this action.
    var localizedName: String {
        switch self {
        case let .kind(kind):
            kind.localizedName
        case .moreOptions:
            Localizations.moreOptions
        }
    }

    // MARK: Methods

    /// The accessibility actions to expose on a row, given the more-options action kinds that
    /// apply to it. "More options" comes first so it is the first entry in the Actions rotor.
    ///
    /// - Parameter kinds: The more-options action kinds applicable to the row.
    /// - Returns: The actions in rotor order, or an empty list when `kinds` is empty (matching rows
    ///   where the more options button is not shown).
    ///
    static func actions(for kinds: [MoreOptionsActionKind]) -> [VaultListItemRowAccessibilityAction] {
        guard !kinds.isEmpty else { return [] }
        return [.moreOptions] + kinds.map(VaultListItemRowAccessibilityAction.kind)
    }
}
