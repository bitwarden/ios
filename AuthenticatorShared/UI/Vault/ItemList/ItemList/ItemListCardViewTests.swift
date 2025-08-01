import BitwardenResources
import SnapshotTesting
import ViewInspector
import XCTest

@testable import AuthenticatorShared

// MARK: - ItemListCardViewTests

class ItemListCardViewTests: BitwardenTestCase {
    // MARK: Tests

    /// Test a snapshot of the ItemListView previews.
    func test_snapshot_ItemListCardView_previews() {
        for preview in ItemListCardView_Previews._allPreviews {
            let name = preview.displayName ?? "Unknown"
            assertSnapshots(
                of: preview.content,
                as: [
                    "\(name)-portrait": .defaultPortrait,
                    "\(name)-portraitDark": .defaultPortraitDark,
                    "\(name)-portraitAX5": .tallPortraitAX5(heightMultiple: 3),
                ]
            )
        }
    }

    /// Test the actions are properly wired up in the ItemListCardView.
    func test_snapshot_ItemListCardView_actions() throws {
        let expectationAction = expectation(description: "action Tapped")
        let expectationClose = expectation(description: "close Tapped")
        let subject = ItemListCardView(
            bodyText: Localizations
                .allowAuthenticatorAppSyncingInSettingsToViewAllYourVerificationCodesHere,
            buttonText: Localizations.takeMeToTheAppSettings,
            leftImage: {},
            titleText: Localizations.syncWithTheBitwardenApp,
            actionTapped: {
                expectationAction.fulfill()
            },
            closeTapped: {
                expectationClose.fulfill()
            }
        )

        try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.close).tap()
        wait(for: [expectationClose])

        try subject.inspect().find(button: Localizations.takeMeToTheAppSettings).tap()
        wait(for: [expectationAction])
    }
}
