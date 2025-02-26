import InlineSnapshotTesting
import UniformTypeIdentifiers
import XCTest

@testable import BitwardenShared

class ActionExtensionHelperTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
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

    /// `canAutofill` returns true if the provider type is supported and the page details contains a
    /// password field.
    func test_canAutofill() throws {
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

        XCTAssertTrue(subject.canAutofill)
    }

    /// `canAutofill` returns false if the provider type is supported but no page details exist.
    func test_canAutofill_missingPageDetails() throws {
        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: URL(string: "https://vault.bitwarden.com")! as NSSecureCoding,
                typeIdentifier: UTType.url.identifier
            ),
        ]

        subject.processInputItems([extensionItem])
        waitFor(subject.context.didFinishLoadingItem)

        XCTAssertFalse(subject.canAutofill)
    }

    /// `canAutofill` returns false if the page details doesn't contain a password field.
    func test_canAutofill_noPasswordField() throws {
        let pageDetailsJsonData = APITestData.loadFromJsonBundle(resource: "pageDetailsWithoutPassword").data
        let pageDetailsJson = String(data: pageDetailsJsonData, encoding: .utf8)

        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: [
                    Constants.appExtensionUrlStringKey: "https://vault.bitwarden.com",
                    Constants.appExtensionWebViewPageDetails: pageDetailsJson,
                ] as NSSecureCoding,
                typeIdentifier: Constants.UTType.appExtensionFillBrowserAction
            ),
        ]

        subject.processInputItems([extensionItem])
        waitFor(subject.context.didFinishLoadingItem)

        XCTAssertFalse(subject.canAutofill)
    }

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
        XCTAssertFalse(subject.canAutofill)
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

    /// `processInputItems(_:)` processes the input items for a change password provider and
    /// returns the data necessary to autofill the changed password.
    func test_processInputItems_changePasswordProvider() throws {
        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: [
                    Constants.appExtensionTitleKey: "Bitwarden",
                    Constants.appExtensionNotesKey: "My Bitwarden Login",
                    Constants.appExtensionOldPasswordKey: "Old Password",
                    Constants.appExtensionPasswordKey: "Password",
                    Constants.appExtensionUrlStringKey: "https://vault.bitwarden.com",
                    Constants.appExtensionUsernameKey: "user@bitwarden.com",
                ] as NSSecureCoding,
                typeIdentifier: Constants.UTType.appExtensionChangePasswordAction
            ),
        ]

        subject.processInputItems([extensionItem])
        waitFor(subject.context.didFinishLoadingItem)

        XCTAssertFalse(subject.canAutofill)
        XCTAssertEqual(subject.context.loginTitle, "Bitwarden")
        XCTAssertEqual(subject.context.notes, "My Bitwarden Login")
        XCTAssertEqual(subject.context.oldPassword, "Old Password")
        XCTAssertEqual(subject.context.password, "Password")
        XCTAssertEqual(subject.context.urlString, "https://vault.bitwarden.com")
        XCTAssertEqual(subject.context.username, "user@bitwarden.com")

        // Output
        let itemData = try XCTUnwrap(
            subject.itemDataToCompleteRequest(
                username: "user@bitwarden.com",
                password: "my-top-secret-password",
                fields: []
            )
        )
        XCTAssertEqual(itemData[Constants.appExtensionPasswordKey] as? String, "")
        XCTAssertEqual(itemData[Constants.appExtensionOldPasswordKey] as? String, "my-top-secret-password")
    }

    /// `processInputItems(_:)` processes the input items for a find login browser provider and
    /// returns the data necessary to autofill the selected cipher on the web page.
    func test_processInputItems_findLoginBrowserProvider_dictionary() throws {
        // swiftlint:disable:previous function_body_length
        let pageDetailsJsonData = APITestData.loadFromJsonBundle(resource: "pageDetails").data
        let pageDetailsJson = String(data: pageDetailsJsonData, encoding: .utf8)
        let pageDetails = try JSONDecoder().decode(PageDetails.self, from: pageDetailsJsonData)

        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: [
                    Constants.appExtensionUrlStringKey: "https://vault.bitwarden.com",
                    Constants.appExtensionWebViewPageDetails: pageDetailsJson,
                ] as NSSecureCoding,
                typeIdentifier: Constants.UTType.appExtensionFillBrowserAction
            ),
        ]

        subject.processInputItems([extensionItem])
        waitFor(subject.context.didFinishLoadingItem)

        XCTAssertTrue(subject.canAutofill)
        XCTAssertEqual(subject.context.pageDetails, pageDetails)
        XCTAssertEqual(subject.context.urlString, "https://vault.bitwarden.com")

        // Output
        let itemData = try XCTUnwrap(
            subject.itemDataToCompleteRequest(
                username: "user@bitwarden.com",
                password: "my-top-secret-password",
                fields: []
            )
        )
        let scriptDictionary = try XCTUnwrap(itemData[Constants.appExtensionWebViewPageFillScript] as? [String: String])
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

    /// `processInputItems(_:)` processes the input items for a find login provider and returns the
    /// data necessary to autofill the selected cipher in another app.
    func test_processInputItems_findLoginProvider() throws {
        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: [
                    Constants.appExtensionUrlStringKey: "https://vault.bitwarden.com",
                ] as NSSecureCoding,
                typeIdentifier: Constants.UTType.appExtensionFindLoginAction
            ),
        ]

        subject.processInputItems([extensionItem])
        waitFor(subject.context.didFinishLoadingItem)

        XCTAssertFalse(subject.canAutofill)
        XCTAssertEqual(subject.context.urlString, "https://vault.bitwarden.com")

        // Output
        let itemData = try XCTUnwrap(
            subject.itemDataToCompleteRequest(
                username: "user@bitwarden.com",
                password: "my-top-secret-password",
                fields: []
            )
        )

        XCTAssertEqual(itemData.count, 2)
        XCTAssertEqual(itemData[Constants.appExtensionPasswordKey] as? String, "my-top-secret-password")
        XCTAssertEqual(itemData[Constants.appExtensionUsernameKey] as? String, "user@bitwarden.com")
    }

    /// `processInputItems(_:)` processes the input items for a save login provider and returns the
    /// data necessary to save the details of a new login.
    func test_processInputItems_saveLoginProvider() throws {
        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: [
                    Constants.appExtensionTitleKey: "Bitwarden",
                    Constants.appExtensionNotesKey: "My Bitwarden Login",
                    Constants.appExtensionOldPasswordKey: "Old Password",
                    Constants.appExtensionPasswordKey: "Password",
                    Constants.appExtensionUrlStringKey: "https://vault.bitwarden.com",
                    Constants.appExtensionUsernameKey: "user@bitwarden.com",
                ] as NSSecureCoding,
                typeIdentifier: Constants.UTType.appExtensionSaveLogin
            ),
        ]

        subject.processInputItems([extensionItem])
        waitFor(subject.context.didFinishLoadingItem)

        XCTAssertFalse(subject.canAutofill)
        XCTAssertEqual(subject.context.loginTitle, "Bitwarden")
        XCTAssertEqual(subject.context.notes, "My Bitwarden Login")
        XCTAssertEqual(subject.context.password, "Password")
        XCTAssertEqual(subject.context.urlString, "https://vault.bitwarden.com")
        XCTAssertEqual(subject.context.username, "user@bitwarden.com")

        XCTAssertTrue(subject.isProviderSaveLogin)

        // Output
        let itemData = try XCTUnwrap(
            subject.itemDataToCompleteRequest(
                username: "user@bitwarden.com",
                password: "my-top-secret-password",
                fields: []
            )
        )

        XCTAssertEqual(itemData.count, 2)
        XCTAssertEqual(itemData[Constants.appExtensionPasswordKey] as? String, "my-top-secret-password")
        XCTAssertEqual(itemData[Constants.appExtensionUsernameKey] as? String, "user@bitwarden.com")
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

        XCTAssertTrue(subject.canAutofill)
        XCTAssertEqual(subject.uri, "https://vault.bitwarden.com")

        let pageDetails = try XCTUnwrap(subject.context.pageDetails)
        try XCTAssertEqual(pageDetails, JSONDecoder().decode(PageDetails.self, from: pageDetailsJsonData))

        // Output
        let itemData = try XCTUnwrap(
            subject.itemDataToCompleteRequest(
                username: "user@bitwarden.com",
                password: "my-top-secret-password",
                fields: []
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
