import UniformTypeIdentifiers
import XCTest

@testable import BitwardenShared

class ActionExtensionHelperTests: BitwardenTestCase {
    // MARK: Properties

    var subject: ActionExtensionHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = ActionExtensionHelper()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `processInputItems(_:)` processes the input items for the extension setup and sets the
    /// `isAppExtensionSetup` if the type identifier is for extension setup.
    func test_processInputItems_extensionSetup() {
        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: "" as NSString,
                typeIdentifier: Constants.UTType.appExtensionSetup
            ),
        ]

        subject.processInputItems([extensionItem])

        XCTAssertTrue(subject.isAppExtensionSetup)
    }

    /// `processInputItems(_:)` processes the input items for the extension setup, but doesn't set
    /// the `isAppExtensionSetup` if the type identifier isn't for extension setup.
    func test_processInputItems_notExtensionSetup() {
        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: "" as NSString,
                typeIdentifier: UTType.text.identifier
            ),
        ]

        subject.processInputItems([extensionItem])

        XCTAssertFalse(subject.isAppExtensionSetup)
    }
}
