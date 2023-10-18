import XCTest

@testable import BitwardenShared

class VaultUnlockStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(account:)` uses the accounts email and web vault host to populate the state.
    func test_init_account() {
        let subject = VaultUnlockState(
            account: .fixture(
                settings: .fixture(
                    environmentUrls: .fixture(
                        webVault: URL(string: "https://test.bitwarden.com")
                    )
                )
            )
        )

        XCTAssertEqual(subject.email, "user@bitwarden.com")
        XCTAssertEqual(subject.webVaultHost, "test.bitwarden.com")
    }

    /// `init(account:)` uses the accounts email and web vault host to populate the state. The web
    /// vault host defaults to bitwarden.com if the account URL is `nil`.
    func test_init_account_nilWebVaultHost() {
        let subject = VaultUnlockState(
            account: .fixture(
                settings: .fixture(
                    environmentUrls: .fixture(
                        webVault: nil
                    )
                )
            )
        )

        XCTAssertEqual(subject.email, "user@bitwarden.com")
        XCTAssertEqual(subject.webVaultHost, "bitwarden.com")
    }
}
