import BitwardenResources
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

class IllustratedMessageViewTests: BitwardenTestCase {
    // MARK: Tests

    /// Tapping the button (if it is there) dispatches the action.
    @MainActor
    func test_button_tap() throws {
        var tapped = false
        let subject: IllustratedMessageView = IllustratedMessageView(
            image: Asset.Images.Illustrations.biometricsPhone,
            style: .mediumImage,
            title: BitwardenShared.Localizations.setUpUnlock,
            message: BitwardenShared.Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
        ) {
            Button {
                tapped = true
            } label: {
                Text(BitwardenShared.Localizations.learnMore)
                    .styleGuide(.subheadline)
                    .foregroundStyle(SharedAsset.Colors.textInteraction.swiftUIColor)
            }
        }
        let button = try subject.inspect().find(button: BitwardenShared.Localizations.learnMore)
        try button.tap()
        XCTAssertTrue(tapped)
    }

    /// Test snapshots of the largeTextTintedIcon style.
    func test_snapshot_largeTextTintedIcon() {
        let subject = IllustratedMessageView(
            image: Asset.Images.plus24,
            style: .largeTextTintedIcon,
            title: BitwardenShared.Localizations.importPasswords,
            message: BitwardenShared.Localizations.startImportCXFDescriptionLong
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
        let subject = IllustratedMessageView(
            image: Asset.Images.Illustrations.biometricsPhone,
            style: .mediumImage,
            title: BitwardenShared.Localizations.setUpUnlock,
            message: BitwardenShared.Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
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
        let subject = IllustratedMessageView(
            image: Asset.Images.Illustrations.biometricsPhone,
            style: .mediumImage,
            title: BitwardenShared.Localizations.setUpUnlock,
            message: BitwardenShared.Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
        ) {
            Button {} label: {
                Text(BitwardenShared.Localizations.learnMore)
                    .styleGuide(.subheadline)
                    .foregroundStyle(SharedAsset.Colors.textInteraction.swiftUIColor)
            }
        }
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
        let subject = IllustratedMessageView(
            image: Asset.Images.Illustrations.biometricsPhone,
            style: .smallImage,
            title: BitwardenShared.Localizations.setUpUnlock,
            message: BitwardenShared.Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
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
