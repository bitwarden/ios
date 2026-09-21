import BitwardenResources
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

struct VaultListStateTests {
    // MARK: Static Properties

    /// All subsets of `VaultListActionCard` cases, used for exhaustive priority testing.
    static let allCardSubsets: [[VaultListActionCard]] = VaultListActionCard.allCases
        .reduce([[]]) { subsets, card in subsets + subsets.map { $0 + [card] } }

    // MARK: Properties

    let subject: VaultListState

    // MARK: Initialization

    init() {
        subject = VaultListState()
    }

    // MARK: Tests

    /// `activeActionCard` returns the highest-priority active card across all flag combinations,
    /// or `nil` when no flags are set. Tests use an empty vault; cards ineligible in an empty vault
    /// (`introducingArchive`) are excluded from the expected result.
    @Test(arguments: allCardSubsets)
    func activeActionCard(activeCards: [VaultListActionCard]) {
        var state = VaultListState()
        state.loadingState = .data([])
        for card in activeCards {
            switch card {
            case .importItems:
                state.importLoginsSetupProgress = .incomplete
            case .introducingArchive:
                state.shouldShowArchiveOnboardingActionCard = true
            case .subscriptionNeedsAttention:
                state.shouldShowSubscriptionAttentionCard = true
            case .upgradeNeeded:
                state.shouldShowPremiumUpgradeActionCard = true
            case .upgradedToPremium:
                state.shouldShowUpgradedToPremiumActionCard = true
            }
        }
        let emptyVaultIneligible: Set<VaultListActionCard> = [.introducingArchive]
        let expected = VaultListActionCard.allCases.first { card in
            activeCards.contains(card) && !emptyVaultIneligible.contains(card)
        }
        #expect(state.activeActionCard == expected)
    }

    /// `activeActionCard` returns `nil` for the archive onboarding card when the vault is empty,
    /// since the card is only relevant when the user has items to archive.
    @Test
    func activeActionCard_introducingArchive_hiddenInEmptyVault() {
        var state = VaultListState()
        state.shouldShowArchiveOnboardingActionCard = true
        state.loadingState = .data([])
        #expect(state.activeActionCard == nil)
    }

    /// `activeActionCard` returns `nil` for the import logins card when the vault is populated,
    /// preserving the original behavior where the card only appeared on an empty vault.
    @Test
    func activeActionCard_importItems_hiddenInPopulatedVault() {
        var state = VaultListState()
        state.importLoginsSetupProgress = .incomplete
        state.loadingState = .data([VaultListSection(id: "1", items: [VaultListItem.fixture()], name: "")])
        #expect(state.activeActionCard == nil)
    }

    /// `navigationTitle` returns "My Vault" when no organizations are present, and "Vaults"
    /// when the user belongs to at least one organization.
    @Test
    func navigationTitle() {
        #expect(subject.navigationTitle == Localizations.myVault)

        var state = subject
        state.organizations = [
            Organization.fixture(id: "1", name: "Org 1"),
        ]
        #expect(state.navigationTitle == Localizations.vaults)
    }

    /// `userInitials` returns the active account's initials from the profile switcher state.
    @Test
    func userInitials() {
        #expect(subject.userInitials == "..")
    }
}
