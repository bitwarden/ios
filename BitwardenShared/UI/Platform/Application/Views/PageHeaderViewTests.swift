import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class PageHeaderViewTests: BitwardenTestCase {
    // MARK: Tests

    /// Tapping the button (if it is there) dispatches the action.
    @MainActor
    func test_button_tap() throws {
        var tapped = false
        let subject = PageHeaderView(
            image: Asset.Images.Illustrations.biometricsPhone,
            style: .mediumImage,
            title: Localizations.setUpUnlock,
            message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins,
            button: PageHeaderViewButton(text: Localizations.learnMore) { tapped = true }
        )
        let button = try subject.inspect().find(button: Localizations.learnMore)
        try button.tap()
        XCTAssertTrue(tapped)
    }

    /// Test snapshots of the largeTextTintedIcon style.
    func test_snapshot_largeTextTintedIcon() {
        let subject = PageHeaderView(
            image: Asset.Images.plus24,
            style: .largeTextTintedIcon,
            title: Localizations.importPasswords,
            message: Localizations.startImportCXPDescriptionLong
        )
        assertSnapshots(
            of: subject,
            as: [
                "portrait": .defaultPortrait,
                "landscape": .defaultLandscape,
            ]
        )
    }

    /// Test snapshots of the mediumImage style.
    func test_snapshot_mediumImage() {
        let subject = PageHeaderView(
            image: Asset.Images.Illustrations.biometricsPhone,
            style: .mediumImage,
            title: Localizations.setUpUnlock,
            message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
        )
        assertSnapshots(
            of: subject,
            as: [
                "portrait": .defaultPortrait,
                "landscape": .defaultLandscape,
            ]
        )
    }

    /// Test snapshots of the mediumImage style with a button.
    func test_snapshot_mediumImage_withButton() {
        let subject = PageHeaderView(
            image: Asset.Images.Illustrations.biometricsPhone,
            style: .mediumImage,
            title: Localizations.setUpUnlock,
            message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins,
            button: PageHeaderViewButton(text: Localizations.learnMore) {}
        )
        assertSnapshots(
            of: subject,
            as: [
                "portrait": .defaultPortrait,
                "landscape": .defaultLandscape,
            ]
        )
    }

    /// Test snapshots of the smallImage style.
    func test_snapshot_smallImage() {
        let subject = PageHeaderView(
            image: Asset.Images.Illustrations.biometricsPhone,
            style: .smallImage,
            title: Localizations.setUpUnlock,
            message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
        )
        assertSnapshots(
            of: subject,
            as: [
                "portrait": .defaultPortrait,
                "landscape": .defaultLandscape,
            ]
        )
    }
}
