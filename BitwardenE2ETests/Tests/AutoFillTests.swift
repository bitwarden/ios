import XCTest

// MARK: - AutoFillTests

/// End-to-end tests for AutoFill through the credential provider extension, driven from Safari.
///
final class AutoFillTests: E2ETestCase {
    // MARK: Setup & Teardown

    override static func setUp() {
        super.setUp()
        MainActor.assumeIsolated {
            SafariRobot.switchToPrivateBrowsing()
        }
    }

    // MARK: Tests

    /// Choosing a login from the Bitwarden list fills a Safari login form.
    @MainActor
    func test_autoFill_fromCredentialList_fillsSafariLoginForm() throws {
        let account = try seeder.createFreeUser()
        let item = SeededLoginItem(
            name: "autofill-safari",
            username: "autofill-safari-user",
            password: "Autofill-Safari-Password",
            uri: "https://webtests.dev",
        )
        try seeder.addLoginItem(item, for: account)
        RobotFlows.logIn(app: app, account: account)
        VaultRobot(app: app).assertShowsItem(named: item.name)
        IOSAutoFillSettingsRobot.open().useBitwardenAsOnlyProvider()

        let form = WebTestsLoginFormRobot.open()
        form.focusUsername()
        AutoFillKeyboardRobot(app: SystemApps.safari).openProvider()
        ExtensionUnlockRobot(app: SystemApps.safari).unlock(with: account.password)
        ExtensionItemListRobot(app: SystemApps.safari).selectItem(named: item.name)

        form.assertUsername(item.username)
            .submit()
            .assertSubmitted(username: item.username, password: item.password)
    }

    /// A passkey saved to Bitwarden on webauthn.io signs in on webauthn.io.
    @MainActor
    func test_passkey_savedOnWebAuthnIO_signsIn() throws {
        let account = try seeder.createFreeUser()
        RobotFlows.logIn(app: app, account: account)
        IOSAutoFillSettingsRobot.open().useBitwardenAsOnlyProvider()

        let passkeyUsername = "e2e-\(UUID().uuidString.prefix(8).lowercased())"
        let site = WebAuthnIORobot.open()
        site.enterUsername(passkeyUsername).register()
        let registrationSheet = PasskeySheetRobot().confirm()
        ExtensionUnlockRobot(app: SystemApps.springboard).unlock(with: account.password)
        ExtensionItemListRobot(app: SystemApps.springboard).savePasskeyAsNewLogin()
        registrationSheet.assertClosed()
        site.assertRegistered()

        site.authenticate()
        PasskeySheetRobot().chooseMoreFromBitwarden().confirm()
        ExtensionUnlockRobot(app: SystemApps.springboard).unlock(with: account.password)
        ExtensionItemListRobot(app: SystemApps.springboard).selectPasskey(forUsername: passkeyUsername)
        site.assertSignedIn()
    }
}
