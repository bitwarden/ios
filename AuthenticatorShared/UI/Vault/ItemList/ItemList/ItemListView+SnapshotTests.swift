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
    func disabletest_snapshot_flightRecorderToastBanner() {
        processor.state.loadingState = .data([])
        processor.state.flightRecorderToastBanner.activeLog = FlightRecorderData.LogMetadata(
            duration: .twentyFourHours,
            startDate: Date(year: 2025, month: 4, day: 3),
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the ItemListView previews.
    func disabletest_snapshot_ItemListView_previews() {
        for preview in ItemListView_Previews._allPreviews {
            let name = preview.displayName ?? "Unknown"
            assertSnapshots(
                of: preview.content,
                as: [
                    "\(name)-portrait": .defaultPortrait,
                    "\(name)-portraitDark": .defaultPortraitDark,
                    "\(name)-portraitAX5": .defaultPortraitAX5,
                ],
            )
        }
    }

    /// Test a snapshot of the ItemListView showing the download card with an empty result.
    @MainActor
    func disabletest_snapshot_ItemListView_card_download_empty() {
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
    func disabletest_snapshot_ItemListView_card_download_with_items() {
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
    func disabletest_snapshot_ItemListView_card_sync_empty() {
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
    func disabletest_snapshot_ItemListView_card_sync_with_items() {
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
}
