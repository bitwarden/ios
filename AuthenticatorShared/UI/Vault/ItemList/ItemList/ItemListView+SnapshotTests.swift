// swiftlint:disable:this file_name
import AuthenticatorSharedMocks
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AuthenticatorShared

// MARK: - ItemListViewTests

class ItemListViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ItemListState, ItemListAction, ItemListEffect>!
    var subject: ItemListView!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let state = ItemListState()
        processor = MockProcessor(state: state)
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2023, month: 12, day: 31)))
        subject = ItemListView(
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

    // MARK: Tests

    @MainActor
    func test_snapshot_flightRecorderToastBanner() {
        processor.state.loadingState = .data([])
        processor.state.flightRecorderToastBanner.activeLog = FlightRecorderData.LogMetadata(
            duration: .twentyFourHours,
            startDate: Date(year: 2025, month: 4, day: 3),
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the ItemListView while loading.
    @MainActor
    func test_snapshot_ItemListView_loading() {
        processor.state.loadingState = .loading(nil)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot of the ItemListView with no items.
    @MainActor
    func test_snapshot_ItemListView_empty() {
        processor.state.loadingState = .data([])
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot of the ItemListView with a favorites section.
    @MainActor
    func test_snapshot_ItemListView_itemsWithFavorite() {
        processor.state.loadingState = .data([
            ItemListSection(id: "Favorites", items: [totpItem(id: "Favorited", name: "Favorited")], name: "Favorites"),
            ItemListSection(
                id: "Section",
                items: [totpItem(id: "One", name: "One"), totpItem(id: "Two", name: "Two")],
                name: "Personal",
            ),
        ])
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot of the ItemListView with items but no favorites.
    @MainActor
    func test_snapshot_ItemListView_itemsWithoutFavorite() {
        processor.state.loadingState = .data([
            ItemListSection(
                id: "Section",
                items: [totpItem(id: "One", name: "One"), totpItem(id: "Two", name: "Two")],
                name: "",
            ),
        ])
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot of the ItemListView with a search that has no results.
    @MainActor
    func test_snapshot_ItemListView_search_noResults() {
        processor.state.searchResults = []
        processor.state.searchText = "Example"
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot of the ItemListView with a search that has one result.
    @MainActor
    func test_snapshot_ItemListView_search_oneResult() {
        processor.state.searchResults = [
            totpItem(id: "One", name: "One", accountName: "person@example.com"),
        ]
        processor.state.searchText = "One"
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot of the ItemListView with a search that has three results.
    @MainActor
    func test_snapshot_ItemListView_search_threeResults() {
        processor.state.searchResults = [
            totpItem(id: "One", name: "One", accountName: "person@example.com"),
            totpItem(id: "Two", name: "One Direction"),
            totpItem(id: "Three", name: "One Song", accountName: "person@example.com"),
        ]
        processor.state.searchText = "One"
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot of the ItemListView with codes of different lengths.
    @MainActor
    func test_snapshot_ItemListView_digits() {
        processor.state.loadingState = .data([ItemListSection.digitsFixture(accountNames: true)])
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot of the ItemListView with a sync error.
    @MainActor
    func test_snapshot_ItemListView_syncError() {
        processor.state.loadingState = .data([
            ItemListSection.digitsFixture(accountNames: true),
            ItemListSection(id: "", items: [.syncError()], name: ""),
        ])
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot of the ItemListView with items shared from the password manager.
    @MainActor
    func test_snapshot_ItemListView_sharedItems() {
        processor.state.loadingState = .data([
            ItemListSection.digitsFixture(accountNames: true),
            ItemListSection(
                id: "",
                items: [totpItem(id: "Shared One", name: "Share", accountName: "person@shared.com")],
                name: "example.com",
            ),
        ])
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot of the ItemListView showing the download card with an empty result.
    @MainActor
    func test_snapshot_ItemListView_card_download_empty() {
        let state = ItemListState(
            itemListCardState: .passwordManagerDownload,
            loadingState: .data([]),
        )
        processor = MockProcessor(state: state)
        subject = ItemListView(
            store: Store(processor: processor),
            timeProvider: timeProvider,
        )

        assertSnapshot(of: NavigationView { subject }, as: .defaultPortrait)
    }

    /// Test a snapshot of the ItemListView showing the download card with results.
    @MainActor
    func test_snapshot_ItemListView_card_download_with_items() {
        let state = ItemListState(
            itemListCardState: .passwordManagerDownload,
            loadingState: .data([ItemListSection.fixture()]),
        )
        processor = MockProcessor(state: state)
        subject = ItemListView(
            store: Store(processor: processor),
            timeProvider: timeProvider,
        )

        assertSnapshot(of: NavigationView { subject }, as: .defaultPortrait)
    }

    /// Test a snapshot of the ItemListView showing the sync card with an empty result.
    @MainActor
    func test_snapshot_ItemListView_card_sync_empty() {
        let state = ItemListState(
            itemListCardState: .passwordManagerSync,
            loadingState: .data([]),
        )
        processor = MockProcessor(state: state)
        subject = ItemListView(
            store: Store(processor: processor),
            timeProvider: timeProvider,
        )

        assertSnapshot(of: NavigationView { subject }, as: .defaultPortrait)
    }

    /// Test a snapshot of the ItemListView showing the sync card with results.
    @MainActor
    func test_snapshot_ItemListView_card_sync_with_items() {
        let state = ItemListState(
            itemListCardState: .passwordManagerSync,
            loadingState: .data([ItemListSection.fixture()]),
        )
        processor = MockProcessor(state: state)
        subject = ItemListView(
            store: Store(processor: processor),
            timeProvider: timeProvider,
        )

        assertSnapshot(of: NavigationView { subject }, as: .defaultPortrait)
    }

    // MARK: Private

    /// Returns a TOTP list item with a fixed code.
    @MainActor
    private func totpItem(id: String, name: String, accountName: String? = nil) -> ItemListItem {
        ItemListItem(
            id: id,
            name: name,
            accountName: accountName,
            itemType: .totp(
                model: ItemListTotpItem(
                    itemView: AuthenticatorItemView.fixture(),
                    totpCode: TOTPCodeModel(
                        code: "123456",
                        codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                        period: 30,
                    ),
                ),
            ),
        )
    }
}
