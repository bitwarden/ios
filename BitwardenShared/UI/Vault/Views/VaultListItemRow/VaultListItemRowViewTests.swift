import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - VaultListItemRowViewTests

class VaultListItemRowViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultListItemRowState, VaultListItemRowAction, VaultListItemRowEffect>!
    var subject: VaultListItemRowView!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let state = VaultListItemRowState(item: .fixture(), hasDivider: false, showWebIcons: true)
        processor = MockProcessor(state: state)
        let store = Store(processor: processor)
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2023, month: 12, day: 31)))
        subject = VaultListItemRowView(store: store, timeProvider: timeProvider)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// Test that tapping the more button dispatches the `.morePressed` action.
    @MainActor
    func test_moreButton_tap() async throws {
        let button = try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.more)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .morePressed)
    }

    /// Test that tapping the totp copy button dispatches the `.copyTOTPCode` action.
    @MainActor
    func test_totpCopyButton_tap() throws {
        let totp = VaultListTOTP.fixture()
        processor.state = VaultListItemRowState(
            item: .fixtureTOTP(
                totp: totp
            ),
            hasDivider: false,
            showWebIcons: true
        )
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copyTotp)
        try button.tap()
        waitFor(!processor.dispatchedActions.isEmpty)
        XCTAssertEqual(processor.dispatchedActions.last, .copyTOTPCode(totp.totpCode.code))
    }

    // MARK: Snapshots

    /// Test that the default view renders correctly.
    @MainActor
    func test_snapshot_default() {
        assertSnapshot(of: subject, as: .fixedSize())
    }

    /// Test that the TOTP type row view renders correctly with a name and username.
    @MainActor
    func test_snapshot_totp() {
        processor.state.item = .fixtureTOTP(
            totp: .fixture(
                loginListView: .fixture(
                    username: "username",
                    totp: .standardTotpKey
                )
            )
        )
        assertSnapshot(of: subject, as: .fixedSize())
    }

    /// Test that the view renders correctly with organization icon.
    @MainActor
    func test_snapshot_organization() {
        processor.state.iconBaseURL = .example
        processor.state.item = .fixture(cipherListView: .fixture(
            organizationId: "org",
            login: .fixture(
                uris: [
                    .fixture(
                        uri: "Test",
                        match: nil
                    ),
                ]
            )
        ))
        assertSnapshot(of: subject, as: .fixedSize())
    }

    /// Test that the view renders correctly with a custom icon.
    @MainActor
    func test_snapshot_showWebIcon() {
        processor.state.iconBaseURL = .example
        processor.state.item = .fixture(
            cipherListView: .fixture(
                login: .fixture(
                    uris: [
                        .fixture(
                            uri: "Test",
                            match: nil
                        ),
                    ]
                )
            )
        )
        assertSnapshot(of: subject, as: .fixedSize())
    }

    /// Test that the password view with username subtitle renders correctly.
    @MainActor
    func test_snapshot_subtitle() {
        processor.state.iconBaseURL = .example
        processor.state.item = .fixture(
            cipherListView: .fixture(
                login: .fixture(
                    username: "username",
                    uris: [
                        .fixture(
                            uri: "Test",
                            match: nil
                        ),
                    ]
                ),
                subtitle: "username"
            )
        )
        assertSnapshot(of: subject, as: .fixedSize())
    }

    /// Test that the Fido2 view renders correctly when Cipher name and RpId are the same.
    @MainActor
    func test_snapshot_fido2Subtitle() {
        processor.state.iconBaseURL = .example
        processor.state.item = .fixture(
            cipherListView: .fixture(
                login: .fixture(
                    fido2Credentials: [
                        .fixture(),
                    ],
                    username: "username",
                    uris: [
                        .fixture(
                            uri: "Test",
                            match: nil
                        ),
                    ]
                ),
                name: "myApp.com"
            ),
            fido2CredentialAutofillView: .fixture(
                rpId: "myApp.com",
                userNameForUi: "another user"
            )
        )
        processor.state.isFromExtension = true
        assertSnapshot(of: subject, as: .fixedSize())
    }

    /// Test that the Fido2 view renders correctly when Cipher name and RpId are different.
    @MainActor
    func test_snapshot_fido2RpIdAndsubtitle() {
        processor.state.iconBaseURL = .example
        processor.state.item = .fixture(
            cipherListView: .fixture(
                login: .fixture(
                    fido2Credentials: [
                        .fixture(),
                    ],
                    username: "username",
                    uris: [
                        .fixture(
                            uri: "Test",
                            match: nil
                        ),
                    ]
                ),
                name: "MyApp"
            ),
            fido2CredentialAutofillView: .fixture(
                rpId: "myApp.com",
                userNameForUi: "another user"
            )
        )
        processor.state.isFromExtension = true
        assertSnapshot(of: subject, as: .fixedSize())
    }
}
