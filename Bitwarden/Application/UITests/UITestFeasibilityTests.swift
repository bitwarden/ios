import XCTest

final class UITestFeasibilityTests: XCTestCase {
    @MainActor
    private func dismissKeyboardIfPresent(_ app: XCUIApplication) {
        if app.keyboards.element.exists {
            if app.keyboards.buttons["return"].exists {
                app.keyboards.buttons["return"].tap()
            } else if app.keyboards.buttons["Go"].exists {
                app.keyboards.buttons["Go"].tap()
            } else {
                app.tapCoordinate(horizontalOffset: 200, verticalOffset: 200)
            }
        }
    }

    @MainActor
    private func configureDirectSelfHosted(_ app: XCUIApplication) {
        let regionSelector = app.buttons["RegionSelectorDropdown"]
        XCTAssertTrue(regionSelector.waitForExistence(timeout: 8))
        regionSelector.tap()

        let selfHosted = app.buttons["Self-hosted"]
        XCTAssertTrue(selfHosted.waitForExistence(timeout: 8))
        selfHosted.tap()

        let serverUrlField = app.textFields["Server URL"]
        XCTAssertTrue(serverUrlField.waitForExistence(timeout: 8))
        serverUrlField.tap()
        serverUrlField.typeText("password.2001y.dev")
        dismissKeyboardIfPresent(app)

        let saveButton = app.buttons["SaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 8))
        saveButton.tap()
    }

    @MainActor
    private func loginToVault(_ app: XCUIApplication) {
        let logInButton = app.buttons["Log in"]
        if logInButton.waitForExistence(timeout: 5) {
            logInButton.tap()
        }

        if app.buttons["RegionSelectorDropdown"].waitForExistence(timeout: 5) {
            configureDirectSelfHosted(app)
        }

        let emailField = app.textFields["LoginEmailAddressEntry"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 8))
        emailField.tap()
        emailField.typeText("mail@tam.nz")
        dismissKeyboardIfPresent(app)

        let passwordField = app.secureTextFields["LoginMasterPasswordEntry"]
        if !passwordField.waitForExistence(timeout: 6) {
            let continueButton = app.buttons["ContinueButton"]
            XCTAssertTrue(continueButton.waitForExistence(timeout: 8))
            continueButton.tap()
            XCTAssertTrue(passwordField.waitForExistence(timeout: 12))
        }

        passwordField.tap()
        passwordField.typeText("Yoshiki20010920")
        dismissKeyboardIfPresent(app)

        if app.buttons["OK, got it!"].waitForExistence(timeout: 3) || app.buttons["Settings"].exists {
            if app.buttons["OK, got it!"].exists {
                app.buttons["OK, got it!"].tap()
            }
            return
        }

        let loginWithMasterPasswordButton = app.buttons["LogInWithMasterPasswordButton"]
        if loginWithMasterPasswordButton.waitForExistence(timeout: 8) {
            loginWithMasterPasswordButton.tap()
        }

        let unlockPasswordField = app.secureTextFields["MasterPasswordEntry"]
        if unlockPasswordField.waitForExistence(timeout: 8), app.buttons["UnlockVaultButton"].exists {
            unlockPasswordField.tap()
            unlockPasswordField.typeText("Yoshiki20010920")
            dismissKeyboardIfPresent(app)
            app.buttons["UnlockVaultButton"].tap()
        }

        let okButton = app.buttons["OK, got it!"]
        if okButton.waitForExistence(timeout: 8) {
            okButton.tap()
        }
    }

    @MainActor
    private func activateSafariExtension(_ app: XCUIApplication) {
        let settingsTab = app.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()

        let autofillSettings = app.buttons["AutofillSettingsButton"]
        XCTAssertTrue(autofillSettings.waitForExistence(timeout: 8))
        autofillSettings.tap()

        let safariExtensionRow = app.buttons["Safari Extension"]
        XCTAssertTrue(safariExtensionRow.waitForExistence(timeout: 8))
        safariExtensionRow.tap()

        let activateButton = app.buttons["Activate Safari Extension"]
        if activateButton.waitForExistence(timeout: 8) {
            activateButton.tap()
        }

        XCTAssertTrue(app.cells["actionGroupCell"].waitForExistence(timeout: 8))
        app.buttons["BackButton"].tap()
    }

    @MainActor
    private func openAutofillFromSafari(_ safari: XCUIApplication) {
        let moreButton = safari.buttons["MoreMenuButton"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 8))
        moreButton.tap()

        let shareButton = safari.buttons["Share"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 8))
        shareButton.tap()

        let reduceActionsCell = safari.cells.matching(
            NSPredicate(format: "identifier == %@ AND label CONTAINS[c] %@", "actionGroupCell", "表示を減らす")
        ).firstMatch
        if reduceActionsCell.waitForExistence(timeout: 2) {
            reduceActionsCell.tap()
        } else {
            let expandActionsCell = safari.cells.matching(
                NSPredicate(format: "identifier == %@ AND label CONTAINS[c] %@", "actionGroupCell", "表示を増やす")
            ).firstMatch
            if expandActionsCell.waitForExistence(timeout: 2) {
                expandActionsCell.tap()
            }
        }

        let bitwardenCell = safari.cells.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Autofill with Bitwarden")
        ).firstMatch
        XCTAssertTrue(bitwardenCell.waitForExistence(timeout: 8))
        bitwardenCell.tap()

        if safari.buttons["UnlockVaultButton"].waitForExistence(timeout: 3) {
            let unlockPasswordField = safari.secureTextFields["MasterPasswordEntry"]
            XCTAssertTrue(unlockPasswordField.waitForExistence(timeout: 5))
            unlockPasswordField.tap()
            unlockPasswordField.typeText("Yoshiki20010920")
            dismissKeyboardIfPresent(safari)

            if safari.navigationBars["New login"].waitForExistence(timeout: 2)
                || safari.navigationBars["Items"].exists
                || safari.buttons["SaveButton"].exists {
                return
            }

            if safari.buttons["UnlockVaultButton"].exists {
                safari.buttons["UnlockVaultButton"].tap()
            }
        }
    }

    @MainActor
    private func ensureSignupFixtureLoginExists(_ app: XCUIApplication, safari: XCUIApplication) {
        openAutofillFromSafari(safari)

        let newLoginBar = safari.navigationBars["New login"]
        if newLoginBar.waitForExistence(timeout: 8) {
            let usernameField = safari.textFields["LoginUsernameEntry"]
            XCTAssertTrue(usernameField.waitForExistence(timeout: 8))
            usernameField.tap()
            usernameField.typeText("fixture-user")

            let passwordField = safari.secureTextFields["LoginPasswordEntry"]
            XCTAssertTrue(passwordField.waitForExistence(timeout: 8))
            passwordField.tap()
            passwordField.typeText("old-secret")
            dismissKeyboardIfPresent(safari)

            let saveButton = safari.buttons["SaveButton"]
            XCTAssertTrue(saveButton.waitForExistence(timeout: 8))
            saveButton.tap()
            sleep(2)
            return
        }

        let itemsBar = safari.navigationBars["Items"]
        if itemsBar.waitForExistence(timeout: 5) {
            let addButton = safari.buttons["AddItemFloatingActionButton"]
            if addButton.waitForExistence(timeout: 5) {
                addButton.tap()
            }

            let newItemButton = safari.buttons["New item"]
            if newItemButton.waitForExistence(timeout: 5) {
                newItemButton.tap()
            }

            XCTAssertTrue(safari.navigationBars["New login"].waitForExistence(timeout: 8))
            let itemNameField = safari.textFields["ItemNameEntry"]
            XCTAssertTrue(itemNameField.waitForExistence(timeout: 8))
            itemNameField.tap()
            itemNameField.typeText("Bitwarden Safari Dev Fixture — Signup")

            let usernameField = safari.textFields["LoginUsernameEntry"]
            usernameField.tap()
            usernameField.typeText("fixture-user")

            let passwordField = safari.secureTextFields["LoginPasswordEntry"]
            passwordField.tap()
            passwordField.typeText("old-secret")

            let uriField = safari.textFields["LoginUriEntry"]
            uriField.tap()
            uriField.typeText("http://127.0.0.1:8123/login.html")
            dismissKeyboardIfPresent(safari)

            let saveButton = safari.buttons["SaveButton"]
            XCTAssertTrue(saveButton.waitForExistence(timeout: 8))
            saveButton.tap()
            sleep(2)
        }

        _ = app
    }

    @MainActor
    func test_directSelfHostedLoginFlow() {
        let app = XCUIApplication(bundleIdentifier: "com.8bit.bitwarden")
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        loginToVault(app)
        XCTAssertTrue(app.secureTextFields["LoginMasterPasswordEntry"].waitForExistence(timeout: 1) || app.navigationBars["MainHeaderBar"].exists)
        print(app.debugDescription)
    }

    @MainActor
    func test_signupFixtureSaveNewLogin() {
        let app = XCUIApplication(bundleIdentifier: "com.8bit.bitwarden")
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        loginToVault(app)
        activateSafariExtension(app)

        safari.launch()
        openAutofillFromSafari(safari)

        XCTAssertTrue(safari.navigationBars["New login"].waitForExistence(timeout: 8))
        let usernameField = safari.textFields["LoginUsernameEntry"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 8))
        usernameField.tap()
        usernameField.typeText("fixture-user")

        let passwordField = safari.secureTextFields["LoginPasswordEntry"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 8))
        passwordField.tap()
        passwordField.typeText("old-secret")
        dismissKeyboardIfPresent(safari)

        let saveButton = safari.buttons["SaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 8))
        saveButton.tap()
        sleep(2)
        print(safari.debugDescription)
    }

    @MainActor
    func test_loginFixtureFillMatchedCredential() {
        let app = XCUIApplication(bundleIdentifier: "com.8bit.bitwarden")
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        loginToVault(app)
        activateSafariExtension(app)

        safari.launch()
        ensureSignupFixtureLoginExists(app, safari: safari)

        safari.terminate()
        safari.launch()
        openAutofillFromSafari(safari)

        let cipherCell = safari.buttons["CipherCell"]
        XCTAssertTrue(cipherCell.waitForExistence(timeout: 8))
        cipherCell.tap()
        sleep(2)

        let usernameValue = safari.textFields["Email or username"].value as? String
        XCTAssertEqual(usernameValue, "fixture-user")
        print(safari.debugDescription)
    }

    @MainActor
    func test_signupFixtureGeneratePasswordFollowUp() {
        let app = XCUIApplication(bundleIdentifier: "com.8bit.bitwarden")
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        loginToVault(app)
        activateSafariExtension(app)

        safari.launch()
        openAutofillFromSafari(safari)

        XCTAssertTrue(safari.navigationBars["New login"].waitForExistence(timeout: 8))
        let regeneratePasswordButton = safari.buttons["RegeneratePasswordButton"]
        XCTAssertTrue(regeneratePasswordButton.waitForExistence(timeout: 8))
        regeneratePasswordButton.tap()

        XCTAssertTrue(safari.navigationBars["Generator"].waitForExistence(timeout: 8))
        let selectButton = safari.buttons["SelectButton"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 8))
        selectButton.tap()

        XCTAssertTrue(safari.navigationBars["New login"].waitForExistence(timeout: 8))
        XCTAssertTrue(safari.secureTextFields["LoginPasswordEntry"].waitForExistence(timeout: 8))
        print(safari.debugDescription)
    }

    @MainActor
    func test_changePasswordFixtureMatchedItemSelection() {
        let app = XCUIApplication(bundleIdentifier: "com.8bit.bitwarden")
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        loginToVault(app)
        activateSafariExtension(app)

        safari.launch()
        ensureSignupFixtureLoginExists(app, safari: safari)

        safari.terminate()
        safari.launch()
        openAutofillFromSafari(safari)

        let itemsBar = safari.navigationBars["Items"]
        XCTAssertTrue(itemsBar.waitForExistence(timeout: 8))

        let cipherCell = safari.buttons["CipherCell"]
        XCTAssertTrue(cipherCell.waitForExistence(timeout: 8))
        cipherCell.tap()

        XCTAssertTrue(safari.buttons["Copy password"].waitForExistence(timeout: 8))
        print(safari.debugDescription)
    }
}

private extension XCUIApplication {
    @MainActor
    func tapCoordinate(horizontalOffset: CGFloat, verticalOffset: CGFloat) {
        coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: horizontalOffset, dy: verticalOffset))
            .tap()
    }
}
