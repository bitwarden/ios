// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

// MARK: - AppearanceViewTests

@testable import BitwardenShared

class AppearanceViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AppearanceState, AppearanceAction, AppearanceEffect>!
    var subject: AppearanceView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AppearanceState())
        let store = Store(processor: processor)

        subject = AppearanceView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Updating the value of the app theme sends the  `.appThemeChanged()` action.
    @MainActor
    func test_appThemeChanged_updateValue() throws {
        processor.state.appTheme = .light
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.theme)
        try menuField.select(newValue: AppTheme.dark)
        XCTAssertEqual(processor.dispatchedActions.last, .appThemeChanged(.dark))
    }

    /// Tapping the language button dispatches the `.languageTapped` action.
    @MainActor
    func test_languageButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.language)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .languageTapped)
    }

    /// The show website icons toggle announces its name to VoiceOver.
    @MainActor
    func test_showWebsiteIconsToggle_accessibilityLabel() throws {
        _ = try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.showWebsiteIcons)
    }

    /// Tapping the show website icons toggle dispatches the `.toggleShowWebsiteIcons(_:)` action.
    @MainActor
    func test_showWebsiteIconsToggle_tap() throws {
        processor.state.isShowWebsiteIconsToggleOn = false
        let toggle = try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.showWebsiteIcons)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .toggleShowWebsiteIcons(true))
    }

    /// The show website icons info button's image has an accessibility label, which names the
    /// custom accessibility action exposed on the toggle.
    @MainActor
    func test_showWebsiteIconsToggle_learnMoreButton_accessibility() throws {
        XCTAssertNoThrow(try subject.inspect().find(ViewType.Image.self) { image in
            try image.accessibilityLabel().string() == Localizations.learnMore
        })
    }
}
