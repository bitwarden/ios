// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

class SyncWithBrowserViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SyncWithBrowserState, SyncWithBrowserAction, SyncWithBrowserEffect>!
    var subject: SyncWithBrowserView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SyncWithBrowserState(
            vaultUrl: "https://example.bitwarden.com",
        ))
        let store = Store(processor: processor)

        subject = SyncWithBrowserView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the "Continue without syncing" button dispatches the `.continueWithoutSyncingTapped` action.
    @MainActor
    func test_continueWithoutSyncingButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.continueWithoutSyncing)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .continueWithoutSyncingTapped)
    }

    /// Tapping the "Launch browser" button dispatches the `.launchBrowserTapped` effect.
    @MainActor
    func test_launchBrowserButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.launchBrowser)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .launchBrowserTapped)
    }
}
