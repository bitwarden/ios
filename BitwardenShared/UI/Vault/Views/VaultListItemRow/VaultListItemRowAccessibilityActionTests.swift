import BitwardenResources
import Testing

@testable import BitwardenShared

// MARK: - VaultListItemRowAccessibilityActionTests

struct VaultListItemRowAccessibilityActionTests {
    // MARK: Tests

    /// `actions(for:)` returns "More options" first, followed by one action per kind, in order.
    @Test
    func actions_kinds() {
        let actions = VaultListItemRowAccessibilityAction.actions(for: [.copyUsername, .copyPassword])
        #expect(actions == [.moreOptions, .kind(.copyUsername), .kind(.copyPassword)])
    }

    /// `actions(for:)` returns no actions when no more-options kinds apply to the row.
    @Test
    func actions_noKinds() {
        #expect(VaultListItemRowAccessibilityAction.actions(for: []).isEmpty)
    }

    /// `effect` maps a kind action to the `.accessibilityMoreOptionsActionPressed` effect.
    @Test
    func effect_kind() {
        #expect(
            VaultListItemRowAccessibilityAction.kind(.copyUsername).effect
                == .accessibilityMoreOptionsActionPressed(.copyUsername),
        )
    }

    /// `effect` maps the "More options" action to the `.morePressed` effect.
    @Test
    func effect_moreOptions() {
        #expect(VaultListItemRowAccessibilityAction.moreOptions.effect == .morePressed)
    }

    /// `localizedName` for the "More options" action is the localized "More options" string.
    @Test
    func localizedName_moreOptions() {
        #expect(VaultListItemRowAccessibilityAction.moreOptions.localizedName == Localizations.moreOptions)
    }
}
