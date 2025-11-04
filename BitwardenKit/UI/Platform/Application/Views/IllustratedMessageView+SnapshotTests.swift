// swiftlint:disable:this file_name
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenKit

@MainActor
class IllustratedMessageViewTests: BitwardenTestCase {
    // MARK: Tests

    /// Test snapshots of the largeTextTintedIcon style.
    func disabletest_snapshot_largeTextTintedIcon() {
        let subject = IllustratedMessageView(
            image: SharedAsset.Icons.plus24,
            style: .largeTextTintedIcon,
            title: Localizations.importPasswords,
            message: Localizations.startImportCXFDescriptionLong,
        )
        assertSnapshots(
            of: subject,
            as: [
                "portrait": .defaultPortrait,
                "landscape": .defaultLandscape,
            ],
        )
    }

    /// Test snapshots of the mediumImage style.
    func disabletest_snapshot_mediumImage() {
        let subject = IllustratedMessageView(
            image: SharedAsset.Icons.unlocked24,
            style: .mediumImage,
            title: Localizations.setUpUnlock,
            message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins,
        )
        assertSnapshots(
            of: subject,
            as: [
                "portrait": .defaultPortrait,
                "landscape": .defaultLandscape,
            ],
        )
    }

    /// Test snapshots of the mediumImage style with a button.
    func disabletest_snapshot_mediumImage_withButton() {
        let subject = IllustratedMessageView(
            image: SharedAsset.Icons.unlocked24,
            style: .mediumImage,
            title: Localizations.setUpUnlock,
            message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins,
        ) {
            Button {} label: {
                Text(Localizations.learnMore)
                    .styleGuide(.subheadline)
                    .foregroundStyle(SharedAsset.Colors.textInteraction.swiftUIColor)
            }
        }
        assertSnapshots(
            of: subject,
            as: [
                "portrait": .defaultPortrait,
                "landscape": .defaultLandscape,
            ],
        )
    }

    /// Test snapshots of the smallImage style.
    func disabletest_snapshot_smallImage() {
        let subject = IllustratedMessageView(
            image: SharedAsset.Icons.unlocked24,
            style: .smallImage,
            title: Localizations.setUpUnlock,
            message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins,
        )
        assertSnapshots(
            of: subject,
            as: [
                "portrait": .defaultPortrait,
                "landscape": .defaultLandscape,
            ],
        )
    }
}
