import BitwardenResources
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class VaultListStateTests: BitwardenTestCase {
    // MARK: Properties

    var subject: VaultListState!

    override func setUp() {
        super.setUp()

        subject = VaultListState()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `navigationTitle` returns the navigation bar title for the view.
    func test_navigationTitle() {
        XCTAssertEqual(subject.navigationTitle, Localizations.myVault)

        subject.organizations = [
            Organization.fixture(id: "1", name: "Org 1"),
        ]
        XCTAssertEqual(subject.navigationTitle, Localizations.vaults)
    }

    /// `userInitials` returns the user initials.
    func test_userInitials() {
        XCTAssertEqual(subject.userInitials, "..")
    }

    /// `activeActionCard` returns `nil` when no cards are active.
    func test_activeActionCard_nil() {
        XCTAssertNil(subject.activeActionCard)
    }

    /// `activeActionCard` returns `.importItems` when only the import logins card is active.
    func test_activeActionCard_importItems() {
        subject.importLoginsSetupProgress = .incomplete
        XCTAssertEqual(subject.activeActionCard, .importItems)
    }

    /// `activeActionCard` returns `.introducingArchive` when only the archive onboarding card is active.
    func test_activeActionCard_introducingArchive() {
        subject.shouldShowArchiveOnboardingActionCard = true
        XCTAssertEqual(subject.activeActionCard, .introducingArchive)
    }

    /// `activeActionCard` returns `.subscriptionNeedsAttention` when the attention card is active.
    func test_activeActionCard_subscriptionNeedsAttention() {
        subject.shouldShowSubscriptionAttentionCard = true
        XCTAssertEqual(subject.activeActionCard, .subscriptionNeedsAttention)
    }

    /// `activeActionCard` returns `.upgradeNeeded` when the upgrade card is active.
    func test_activeActionCard_upgradeNeeded() {
        subject.shouldShowPremiumUpgradeActionCard = true
        XCTAssertEqual(subject.activeActionCard, .upgradeNeeded)
    }

    /// `activeActionCard` returns `.upgradedToPremium` when the confirmation card is active.
    func test_activeActionCard_upgradedToPremium() {
        subject.shouldShowUpgradedToPremiumActionCard = true
        XCTAssertEqual(subject.activeActionCard, .upgradedToPremium)
    }

    /// `activeActionCard` respects priority — `.upgradedToPremium` wins over all others.
    func test_activeActionCard_priority_upgradedToPremiumWins() {
        subject.shouldShowUpgradedToPremiumActionCard = true
        subject.shouldShowPremiumUpgradeActionCard = true
        subject.shouldShowSubscriptionAttentionCard = true
        subject.shouldShowArchiveOnboardingActionCard = true
        subject.importLoginsSetupProgress = .incomplete
        XCTAssertEqual(subject.activeActionCard, .upgradedToPremium)
    }

    /// `activeActionCard` respects priority — `.upgradeNeeded` wins over lower-priority cards.
    func test_activeActionCard_priority_upgradeNeededWins() {
        subject.shouldShowPremiumUpgradeActionCard = true
        subject.shouldShowSubscriptionAttentionCard = true
        subject.shouldShowArchiveOnboardingActionCard = true
        XCTAssertEqual(subject.activeActionCard, .upgradeNeeded)
    }

    /// `activeActionCard` respects priority — `.introducingArchive` wins over `.importItems`.
    func test_activeActionCard_priority_introducingArchiveWins() {
        subject.shouldShowArchiveOnboardingActionCard = true
        subject.importLoginsSetupProgress = .incomplete
        XCTAssertEqual(subject.activeActionCard, .introducingArchive)
    }
}
