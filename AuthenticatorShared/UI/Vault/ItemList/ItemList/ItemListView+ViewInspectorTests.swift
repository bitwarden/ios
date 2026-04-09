// swiftlint:disable:this file_name
import AuthenticatorSharedMocks
import BitwardenKit
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
    func test_actionCard_close_download() async throws {
        let state = ItemListState(
            itemListCardState: .passwordManagerDownload,
            loadingState: .data([ItemListSection.fixture()]),
        )
        processor = MockProcessor(state: state)
        subject = ItemListView(
            store: Store(processor: processor),
            timeProvider: timeProvider,
        )

        let actionCard = try subject.inspect().find(actionCard: Localizations.downloadTheBitwardenApp)
        try await actionCard.find(asyncButton: Localizations.close).tap()

        XCTAssertEqual(processor.effects.last, .closeCard(.passwordManagerDownload))
    }

    /// Test the close taps trigger the associated effect.
    @MainActor
    func test_actionCard_close_sync() async throws {
        let state = ItemListState(
            itemListCardState: .passwordManagerSync,
            loadingState: .data([]),
        )
        processor = MockProcessor(state: state)
        subject = ItemListView(
            store: Store(processor: processor),
            timeProvider: timeProvider,
        )

        let actionCard = try subject.inspect().find(actionCard: Localizations.syncWithTheBitwardenApp)
        try await actionCard.find(asyncButton: Localizations.close).tap()

        XCTAssertEqual(processor.effects.last, .closeCard(.passwordManagerSync))
    }

    /// Tapping the go to settings button in the flight recorder toast banner dispatches the
    /// `.navigateToFlightRecorderSettings` action.
    @MainActor
    func test_flightRecorderToastBannerGoToSettings_tap() async throws {
        processor.state.flightRecorderToastBanner.activeLog = FlightRecorderData.LogMetadata(
            duration: .eightHours,
            startDate: Date(year: 2025, month: 4, day: 3),
        )
        let button = try subject.inspect().find(button: Localizations.goToSettings)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.navigateToFlightRecorderSettings])
    }
}
