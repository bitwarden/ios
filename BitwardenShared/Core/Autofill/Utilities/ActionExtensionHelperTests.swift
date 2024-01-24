import InlineSnapshotTesting
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

    /// `processInputItems(_:)` processes the input items for a web URL provider and returns the
    /// data necessary to autofill the selected cipher on the web page.
    func test_processInputItems_webUrlProvider() throws { // swiftlint:disable:this function_body_length
        let pageDetailsJsonData = APITestData.loadFromJsonBundle(resource: "pageDetails").data
        let pageDetailsJson = try XCTUnwrap(String(data: pageDetailsJsonData, encoding: .utf8))

        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: [
                    NSExtensionJavaScriptPreprocessingResultsKey: [
                        Constants.appExtensionUrlStringKey: "https://vault.bitwarden.com",
                        Constants.appExtensionWebViewPageDetails: pageDetailsJson,
                    ],
                ] as NSSecureCoding,
                typeIdentifier: UTType.propertyList.identifier
            ),
        ]

        subject.processInputItems([extensionItem])
        waitFor(subject.context.didFinishLoadingItem)

        XCTAssertEqual(subject.uri, "https://vault.bitwarden.com")

        let pageDetails = try XCTUnwrap(subject.context.pageDetails)
        try XCTAssertEqual(pageDetails, JSONDecoder().decode(PageDetails.self, from: pageDetailsJsonData))

        // Output
        let itemData = try XCTUnwrap(
            subject.itemDataToCompleteRequest(
                username: "user@bitwarden.com",
                password: "my-top-secret-password"
            ) as? [String: [String: String]]
        )
        let scriptDictionary = try XCTUnwrap(itemData[NSExtensionJavaScriptFinalizeArgumentKey])
        let scriptJson = try XCTUnwrap(scriptDictionary[Constants.appExtensionWebViewPageFillScript]?.prettyPrintedJson)
        assertInlineSnapshot(of: scriptJson, as: .lines) {
            """
            {
              "documentUUID" : "oneshotUUID",
              "metadata" : [

              ],
              "options" : [

              ],
              "properties" : [

              ],
              "script" : [
                [
                  "click_on_opid",
                  "__0"
                ],
                [
                  "fill_by_opid",
                  "__0",
                  "my-top-secret-password"
                ],
                [
                  "focus_by_opid",
                  "__0"
                ]
              ]
            }
            """
        }
    }
}

private extension String {
    var prettyPrintedJson: String? {
        guard let object = try? JSONSerialization.jsonObject(with: Data(utf8)),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let prettyPrintedString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return prettyPrintedString
    }
}
