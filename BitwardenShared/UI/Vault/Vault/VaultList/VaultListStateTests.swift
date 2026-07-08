import BitwardenResources
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

struct VaultListStateTests {
    // MARK: Static Properties

    /// All 32 subsets of `VaultListActionCard` cases, used for exhaustive priority testing.
    static let allCardSubsets: [[VaultListActionCard]] = {
        let allCards: [VaultListActionCard] = [
            .importItems, .introducingArchive, .subscriptionNeedsAttention, .upgradeNeeded, .upgradedToPremium,
        ]
        return allCards.reduce([[]]) { subsets, card in subsets + subsets.map { $0 + [card] } }
    }()

    /// The expected priority order of `VaultListActionCard` cases, from highest to lowest.
    static let priorityOrder: [VaultListActionCard] = [
        .upgradedToPremium, .upgradeNeeded, .subscriptionNeedsAttention, .introducingArchive, .importItems,
    ]

    // MARK: Properties

    let subject: VaultListState

    // MARK: Initialization

    init() {
        subject = VaultListState()
    }

    // MARK: Tests

    /// `activeActionCard` returns the highest-priority active card across all 32 flag combinations,
    /// or `nil` when no flags are set.
    @Test(arguments: allCardSubsets)
    func activeActionCard(activeCards: [VaultListActionCard]) {
        var state = VaultListState()
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
        let expected = Self.priorityOrder.first { activeCards.contains($0) }
        #expect(state.activeActionCard == expected)
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
