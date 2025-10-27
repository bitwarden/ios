// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class VaultItemSelectionViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultItemSelectionState, VaultItemSelectionAction, VaultItemSelectionEffect>!
    var subject: VaultItemSelectionView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: VaultItemSelectionState(
            iconBaseURL: nil,
            totpKeyModel: .fixtureExample,
        ))
        let store = Store(processor: processor)

        subject = VaultItemSelectionView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The empty view renders correctly.
    @MainActor
    func disabletest_snapshot_cipherSelection_empty() {
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The empty view renders correctly when there's no account or issuer.
    @MainActor
    func disabletest_snapshot_cipherSelection_emptyNoAccountOrIssuer() {
        processor = MockProcessor(state: VaultItemSelectionState(
            iconBaseURL: nil,
            totpKeyModel: .fixtureMinimum,
        ))
        subject = VaultItemSelectionView(store: Store(processor: processor))

        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait],
        )
    }

    /// The populated view renders correctly.
    @MainActor
    func disabletest_snapshot_cipherSelection_populated() {
        let account = ProfileSwitcherItem.anneAccount
        processor.state.profileSwitcherState.accounts = [account]
        processor.state.profileSwitcherState.activeAccountId = account.userId
        let ciphers: [CipherListView] = [
            .fixture(
                id: "1",
                login: .fixture(
                    username: "user@bitwarden.com",
                ),
                name: "Example",
                subtitle: "user@bitwarden.com",
            ),
            .fixture(
                id: "2",
                login: .fixture(
                    username: "user@bitwarden.com",
                ),
                name: "Example Co",
                subtitle: "user@bitwarden.com",
            ),
        ]
        processor.state.vaultListSections = [
            VaultListSection(
                id: Localizations.matchingItems,
                items: ciphers.compactMap(VaultListItem.init),
                name: Localizations.matchingItems,
            ),
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The search view renders correctly when there's search results.
    @MainActor
    func disabletest_snapshot_cipherSelection_search() {
        let ciphers: [CipherListView] = [
            .fixture(
                id: "1",
                login: .fixture(
                    username: "user@bitwarden.com",
                ),
                name: "Example",
                subtitle: "user@bitwarden.com",
            ),
            .fixture(
                id: "2",
                login: .fixture(
                    username: "user@bitwarden.com",
                ),
                name: "Example Co",
                subtitle: "user@bitwarden.com",
            ),
        ]
        processor.state.searchResults = ciphers.compactMap(VaultListItem.init)
        processor.state.searchText = "Example"
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The search view renders correctly when there's no search results.
    @MainActor
    func disabletest_snapshot_cipherSelection_searchEmpty() {
        processor.state.searchText = "Example"
        processor.state.showNoResults = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
