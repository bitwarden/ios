// swiftlint:disable:this file_name
import BitwardenResources
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
        let subject = IllustratedMessageView(
            image: Asset.Images.Illustrations.biometricsPhone,
            style: .mediumImage,
            title: Localizations.setUpUnlock,
            message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins,
        ) {
            Button {
                tapped = true
            } label: {
                Text(Localizations.learnMore)
                    .styleGuide(.subheadline)
                    .foregroundStyle(SharedAsset.Colors.textInteraction.swiftUIColor)
            }
        }
        let button = try subject.inspect().find(button: Localizations.learnMore)
        try button.tap()
        XCTAssertTrue(tapped)
    }
}
