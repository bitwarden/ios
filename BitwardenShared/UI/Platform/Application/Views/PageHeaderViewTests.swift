import SnapshotTesting
import XCTest

@testable import BitwardenShared

class PageHeaderViewTests: BitwardenTestCase {
    // MARK: Tests

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
