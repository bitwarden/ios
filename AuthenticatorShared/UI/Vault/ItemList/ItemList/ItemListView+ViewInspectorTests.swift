// swiftlint:disable:this file_name
import BitwardenKitMocks
import BitwardenResources
import SwiftUI
import ViewInspector
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

    /// Test the close taps trigger the associated effect.
    @MainActor
    func test_itemListCardView_close_download() throws {
        let state = ItemListState(
            itemListCardState: .passwordManagerDownload,
            loadingState: .data([ItemListSection.fixture()]),
        )
        processor = MockProcessor(state: state)
        subject = ItemListView(
            store: Store(processor: processor),
            timeProvider: timeProvider,
        )

        try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.close).tap()

        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .closeCard(.passwordManagerDownload))
    }

    /// Test the close taps trigger the associated effect.
    @MainActor
    func test_itemListCardView_close_sync() throws {
        let state = ItemListState(
            itemListCardState: .passwordManagerSync,
            loadingState: .data([]),
        )
        processor = MockProcessor(state: state)
        subject = ItemListView(
            store: Store(processor: processor),
            timeProvider: timeProvider,
        )

        try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.close).tap()

        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .closeCard(.passwordManagerSync))
    }
}
