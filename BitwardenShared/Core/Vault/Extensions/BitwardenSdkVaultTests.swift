// swiftlint:disable:this file_name

import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - CipherView

class CipherViewTests: BitwardenTestCase {
    // MARK: Properties

    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        timeProvider = MockTimeProvider(.mockTime(Date(year: 2024, month: 6, day: 28)))
    }

    override func tearDown() {
        super.tearDown()

        timeProvider = nil
    }

    // MARK: Tests

    /// `init(fido2CredentialNewView:timeProvider:)` initializes correctly
    func test_init_fido2CredentialNewView_defaultValues() {
        let fido2CredentialNewView = Fido2CredentialNewView.fixture()
        let subject = CipherView(fido2CredentialNewView: fido2CredentialNewView, timeProvider: timeProvider)
        XCTAssertEqual(
            subject,
            CipherView(
                id: nil,
                organizationId: nil,
                folderId: nil,
                collectionIds: [],
                key: nil,
                name: "myApp.com",
                notes: nil,
                type: .login,
                login: BitwardenSdk.LoginView(
                    username: "",
                    password: nil,
                    passwordRevisionDate: nil,
                    uris: [
                        LoginUriView(uri: "myApp.com", match: nil, uriChecksum: nil),
                    ],
                    totp: nil,
                    autofillOnPageLoad: nil,
                    fido2Credentials: nil
                ),
                identity: nil,
                card: nil,
                secureNote: nil,
                favorite: false,
                reprompt: .none,
                organizationUseTotp: false,
                edit: false,
                viewPassword: true,
                localData: nil,
                attachments: nil,
                fields: nil,
                passwordHistory: nil,
                creationDate: timeProvider.presentTime,
                deletedDate: nil,
                revisionDate: timeProvider.presentTime
            )
        )
    }

    /// `init(fido2CredentialNewView:timeProvider:)` initializes correctly with rpName and username
    func test_init_fido2CredentialNewView_rpNameUsername() {
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(
            userName: "username",
            rpName: "MyApp"
        )
        let subject = CipherView(fido2CredentialNewView: fido2CredentialNewView, timeProvider: timeProvider)
        XCTAssertEqual(
            subject,
            CipherView(
                id: nil,
                organizationId: nil,
                folderId: nil,
                collectionIds: [],
                key: nil,
                name: "MyApp",
                notes: nil,
                type: .login,
                login: BitwardenSdk.LoginView(
                    username: "username",
                    password: nil,
                    passwordRevisionDate: nil,
                    uris: [
                        LoginUriView(uri: "myApp.com", match: nil, uriChecksum: nil),
                    ],
                    totp: nil,
                    autofillOnPageLoad: nil,
                    fido2Credentials: nil
                ),
                identity: nil,
                card: nil,
                secureNote: nil,
                favorite: false,
                reprompt: .none,
                organizationUseTotp: false,
                edit: false,
                viewPassword: true,
                localData: nil,
                attachments: nil,
                fields: nil,
                passwordHistory: nil,
                creationDate: timeProvider.presentTime,
                deletedDate: nil,
                revisionDate: timeProvider.presentTime
            )
        )
    }
}
