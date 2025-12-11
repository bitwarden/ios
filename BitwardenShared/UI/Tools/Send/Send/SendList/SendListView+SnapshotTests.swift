// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SendListViewTests

class SendListViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SendListState, SendListAction, SendListEffect>!
    var subject: SendListView!

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SendListState())
        subject = SendListView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The view renders correctly when there are no items.
    @MainActor
    func disabletest_snapshot_empty() {
        processor.state = .empty
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultLandscape,
                .defaultPortraitAX5,
            ],
        )
    }

    /// The view renders correctly when it's loading.
    @MainActor
    func disabletest_snapshot_loading() {
        processor.state = .loading
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
            ],
        )
    }

    /// The view renders correctly when the search results are empty.
    @MainActor
    func disabletest_snapshot_search_empty() {
        processor.state.searchResults = []
        processor.state.searchText = "Searching"
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultLandscape,
                .defaultPortraitAX5,
            ],
        )
    }

    /// The view renders correctly when there are search results.
    @MainActor
    func disabletest_snapshot_search_results() {
        processor.state = .hasSearchResults
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultLandscape,
                .defaultPortraitAX5,
            ],
        )
    }

    /// The view renders in correctly when there are sends.
    @MainActor
    func disabletest_snapshot_values() {
        processor.state = .content
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultLandscape,
                .defaultPortraitAX5,
            ],
        )
    }

    /// The view renders correctly when there are sends.
    @MainActor
    func disabletest_snapshot_textValues() {
        processor.state = .contentTextType
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultLandscape,
                .defaultPortraitAX5,
            ],
        )
    }
}
