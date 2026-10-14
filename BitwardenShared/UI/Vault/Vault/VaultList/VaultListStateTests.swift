import BitwardenResources
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

struct VaultListStateTests {
    // MARK: Static Properties

    /// All action cards, in priority order from highest to lowest.
    static let actionCardsByPriority: [VaultListActionCard] = [
        .organizationBanner(.fixture()),
        .upgradedToPremium,
        .upgradeNeeded,
        .subscriptionNeedsAttention,
        .introducingArchive,
        .importItems,
    ]

    /// Every combination of action cards that could be eligible at the same time, from none to all
    /// of them, used for exhaustive priority testing.
    static let allCardCombinations: [[VaultListActionCard]] = actionCardsByPriority
        .reduce([[]]) { combinations, card in combinations + combinations.map { $0 + [card] } }

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
    @Test(arguments: allCardCombinations)
    func activeActionCard(activeCards: [VaultListActionCard]) {
        var state = VaultListState()
        state.loadingState = .data([])
        for card in activeCards {
            switch card {
            case .importItems:
                state.importLoginsSetupProgress = .incomplete
            case .introducingArchive:
                state.shouldShowArchiveOnboardingActionCard = true
            case let .organizationBanner(data):
                state.organizationUserNotificationBannerData = data
            case .subscriptionNeedsAttention:
                state.shouldShowSubscriptionAttentionCard = true
            case .upgradeNeeded:
                state.shouldShowPremiumUpgradeActionCard = true
            case .upgradedToPremium:
                state.shouldShowUpgradedToPremiumActionCard = true
            }
        }
        let expected = Self.actionCardsByPriority.first { card in
            // Get first passed in card, sorted by priority, that is not `.introducingArchive`.
            activeCards.contains(card) && card != .introducingArchive
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

    /// `activeActionCard` returns the archive onboarding card when the vault is populated, since
    /// the user has items to archive.
    @Test
    func activeActionCard_introducingArchive_shownInPopulatedVault() {
        var state = VaultListState()
        state.shouldShowArchiveOnboardingActionCard = true
        state.loadingState = .data([VaultListSection(id: "1", items: [VaultListItem.fixture()], name: "")])
        #expect(state.activeActionCard == .introducingArchive)
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
