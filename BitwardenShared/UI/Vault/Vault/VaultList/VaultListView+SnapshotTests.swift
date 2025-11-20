// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - VaultListViewTests

class VaultListViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultListState, VaultListAction, VaultListEffect>!
    var subject: VaultListView!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let account = ProfileSwitcherItem.fixture(
            email: "anne.account@bitwarden.com",
            userInitials: "AA",
        )
        let state = VaultListState(
            profileSwitcherState: ProfileSwitcherState(
                accounts: [account],
                activeAccountId: account.userId,
                allowLockAndLogout: true,
                isVisible: false,
            ),
        )
        processor = MockProcessor(state: state)
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2023, month: 12, day: 31)))
        subject = VaultListView(
            store: Store(processor: processor),
            timeProvider: timeProvider,
        )
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Snapshots

    @MainActor
    func disabletest_snapshot_empty() {
        processor.state.profileSwitcherState.isVisible = false
        processor.state.loadingState = .data([])

        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultLandscape])
    }

    @MainActor
    func disabletest_snapshot_empty_singleAccountProfileSwitcher() {
        processor.state.profileSwitcherState.isVisible = true
        processor.state.loadingState = .data([])

        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark])
    }

    @MainActor
    func disabletest_snapshot_errorState() {
        processor.state.loadingState = .error(
            errorMessage: Localizations.weAreUnableToProcessYourRequestPleaseTryAgainOrContactUs,
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_flightRecorderToastBanner() {
        processor.state.loadingState = .data([])
        processor.state.flightRecorderToastBanner.activeLog = FlightRecorderData.LogMetadata(
            duration: .twentyFourHours,
            startDate: Date(year: 2025, month: 4, day: 3),
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_loading() {
        processor.state.loadingState = .loading(nil)
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_myVault() {
        processor.state.loadingState = .data([
            VaultListSection(
                id: "",
                items: [
                    .fixture(cipherListView: .fixture(
                        login: .fixture(username: "email@example.com"),
                        name: "Example",
                        subtitle: "email@example.com",
                    )),
                    .fixture(cipherListView: .fixture(id: "12", name: "Example", type: .secureNote)),
                    .fixture(cipherListView: .fixture(
                        id: "13",
                        organizationId: "1",
                        login: .fixture(username: "user@bitwarden.com"),
                        name: "Bitwarden",
                        subtitle: "user@bitwarden.com",
                        attachments: 1,
                    )),
                ],
                name: "Favorites",
            ),
            VaultListSection(
                id: "2",
                items: [
                    VaultListItem(
                        id: "21",
                        itemType: .group(.login, 123),
                    ),
                    VaultListItem(
                        id: "22",
                        itemType: .group(.card, 25),
                    ),
                    VaultListItem(
                        id: "23",
                        itemType: .group(.identity, 1),
                    ),
                    VaultListItem(
                        id: "24",
                        itemType: .group(.secureNote, 0),
                    ),
                ],
                name: "Types",
            ),
        ])
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    @MainActor
    func disabletest_snapshot_withSearchResult() {
        processor.state.searchText = "Exam"
        processor.state.searchResults = [
            .fixture(cipherListView: .fixture(
                login: .fixture(username: "email@example.com"),
                name: "Example",
            )),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_withMultipleSearchResults() {
        processor.state.searchText = "Exam"
        processor.state.searchResults = [
            .fixture(cipherListView: .fixture(
                id: "1",
                login: .fixture(username: "email@example.com"),
                name: "Example",
            )),
            .fixture(cipherListView: .fixture(
                id: "2",
                login: .fixture(username: "email@example.com"),
                name: "Example",
            )),
            .fixture(cipherListView: .fixture(
                id: "3",
                login: .fixture(username: "email@example.com"),
                name: "Example",
            )),
            .fixture(cipherListView: .fixture(
                id: "4",
                login: .fixture(username: "email@example.com"),
                name: "Example",
            )),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_withoutSearchResult() {
        processor.state.searchText = "Exam"
        processor.state.searchResults = []
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the VaultListView previews.
    @MainActor
    func disabletest_snapshot_vaultListView_previews() {
        for preview in VaultListView_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [.defaultPortrait],
            )
        }
    }
}
