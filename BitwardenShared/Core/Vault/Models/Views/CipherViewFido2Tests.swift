import BitwardenSdk
import XCTest

@testable import BitwardenShared

class CipherViewFido2Tests: BitwardenTestCase {
    // MARK: Tests

    /// `hasFido2Credentials` with no login type returns that doesn't have Fido2 credentials.
    func test_hasFido2Credentials_notLogin() {
        let subject = CipherView.fixture(type: .card)
        XCTAssertFalse(subject.hasFido2Credentials)
    }

    /// `hasFido2Credentials` with login type but no login returns that doesn't have Fido2 credentials.
    func test_hasFido2Credentials_noLogin() {
        let subject = CipherView.fixture(type: .login)
        XCTAssertFalse(subject.hasFido2Credentials)
    }

    /// `hasFido2Credentials` with login that doesn't have Fido2 credentials.
    func test_hasFido2Credentials_noFido2Credentials() {
        let subject = CipherView.fixture(login: LoginView.fixture(), type: .login)
        XCTAssertFalse(subject.hasFido2Credentials)
    }

    /// `hasFido2Credentials` with login and Fido2 credentials returns `true`.
    func test_hasFido2Credentials_withFido2Credentials() {
        let subject = CipherView.fixture(
            login: LoginView.fixture(fido2Credentials: [Fido2CredentialView.fixture()]),
            type: .login
        )
        XCTAssertTrue(subject.hasFido2Credentials)
    }

    /// `mainFido2Credential` with no login
    func test_mainFido2Credential_noLogin() {
        let subject = CipherView.fixture(type: .login)
        XCTAssertNil(subject.mainFido2Credential)
    }

    /// `mainFido2Credential` with login and Fido2 credentials
    func test_mainFido2Credential_withLoginAndFido2Credentials() {
        let subject = CipherView.fixture(
            login: LoginView.fixture(fido2Credentials: [Fido2CredentialView.fixture()]),
            type: .login
        )
        XCTAssertNotNil(subject.mainFido2Credential)
    }

    /// `mainFido2CredentialUsername` with login and Fido2 credentials username
    func test_mainFido2CredentialUsername_withMainFido2CredentialUsername() {
        let expected = "username"
        let subject = CipherView.fixture(
            login: LoginView.fixture(
                fido2Credentials: [Fido2CredentialView.fixture(userDisplayName: "userDisplayName", userName: expected)],
                username: "loginName"
            ),
            name: "name",
            type: .login
        )

        XCTAssertEqual(expected, subject.mainFido2CredentialUsername)
    }

    /// `mainFido2CredentialUsername` with login and Fido2 credentials with `userDisplayName` but no `username`
    func test_mainFido2CredentialUsername_userDisplayName() {
        let expected = "userDisplayName"

        CombinatorialTestRunner.runWithEachValue(values: [nil, "", "   "]) { fido2Username in
            let subject = CipherView.fixture(
                login: LoginView.fixture(
                    fido2Credentials: [Fido2CredentialView.fixture(userDisplayName: expected, userName: fido2Username)],
                    username: "loginName"
                ),
                name: "name",
                type: .login
            )

            XCTAssertEqual(
                expected,
                subject.mainFido2CredentialUsername,
                "Failed with fido2Username: \(String(describing: fido2Username))"
            )
        }
    }

    /// `mainFido2CredentialUsername` with login and Fido2 credentials with no `username` nor `userDisplayName`
    /// but with login `username`.
    func test_mainFido2CredentialUsername_loginUsername() {
        let expected = "loginUsername"

        CombinatorialTestRunner.runCombined(
            values1: [nil, "", "   "],
            values2: [nil, "", "   "]
        ) { fido2Username, fido2UserDisplayName in
            let subject = CipherView.fixture(
                login: LoginView.fixture(
                    fido2Credentials: [
                        Fido2CredentialView.fixture(
                            userDisplayName: fido2UserDisplayName,
                            userName: fido2Username
                        ),
                    ],
                    username: expected
                ),
                name: "name",
                type: .login
            )

            XCTAssertEqual(expected, subject.mainFido2CredentialUsername)
        }

        // no Fido2 credentials
        let subjectWithoutFido2Credentials = CipherView.fixture(
            login: LoginView.fixture(
                username: expected
            ),
            name: "name",
            type: .login
        )

        XCTAssertEqual(expected, subjectWithoutFido2Credentials.mainFido2CredentialUsername)

        // empty Fido2 credentials
        let subjectWithEmptyFido2Credentials = CipherView.fixture(
            login: LoginView.fixture(
                fido2Credentials: [],
                username: expected
            ),
            name: "name",
            type: .login
        )

        XCTAssertEqual(expected, subjectWithEmptyFido2Credentials.mainFido2CredentialUsername)
    }

    /// `mainFido2CredentialUsername` with login and Fido2 credentials with no `username` nor `userDisplayName`
    /// nor login `username` but with cipher `name`.
    func test_mainFido2CredentialUsername_cipherName() {
        let expected = "name"

        CombinatorialTestRunner.runCombined(
            values1: [nil, "", "   "],
            values2: [nil, "", "   "],
            values3: [nil, "", "   "]
        ) { fido2Username, fido2UserDisplayName, loginUsername in
            let subject = CipherView.fixture(
                login: LoginView.fixture(
                    fido2Credentials: [
                        Fido2CredentialView.fixture(
                            userDisplayName: fido2UserDisplayName,
                            userName: fido2Username
                        ),
                    ],
                    username: loginUsername
                ),
                name: expected,
                type: .login
            )

            XCTAssertEqual(expected, subject.mainFido2CredentialUsername)
        }

        // no Fido2 credentials
        CombinatorialTestRunner.runWithEachValue(values: [nil, "", "   "]) { loginUsername in
            let subject = CipherView.fixture(
                login: LoginView.fixture(
                    username: loginUsername
                ),
                name: expected,
                type: .login
            )

            XCTAssertEqual(expected, subject.mainFido2CredentialUsername)
        }

        // empty Fido2 credentials
        CombinatorialTestRunner.runWithEachValue(values: [nil, "", "   "]) { loginUsername in
            let subject = CipherView.fixture(
                login: LoginView.fixture(
                    fido2Credentials: [],
                    username: loginUsername
                ),
                name: expected,
                type: .login
            )

            XCTAssertEqual(expected, subject.mainFido2CredentialUsername)
        }
    }

    /// `mainFido2CredentialUsername` with login and Fido2 credentials with no `username` nor `userDisplayName`
    /// nor login `username` nor cipher `name` returns default `unknownAccount`.
    func test_mainFido2CredentialUsername_unknownAccount() {
        let expected = Localizations.unknownAccount

        CombinatorialTestRunner.runCombined(
            values1: [nil, "", "   "],
            values2: [nil, "", "   "],
            values3: [nil, "", "   "],
            values4: ["", "   "]
        ) { fido2Username, fido2UserDisplayName, loginUsername, cipherName in
            let subject = CipherView.fixture(
                login: LoginView.fixture(
                    fido2Credentials: [
                        Fido2CredentialView.fixture(
                            userDisplayName: fido2UserDisplayName,
                            userName: fido2Username
                        ),
                    ],
                    username: loginUsername
                ),
                name: cipherName,
                type: .login
            )

            XCTAssertEqual(expected, subject.mainFido2CredentialUsername)
        }

        // no Fido2 credentials
        CombinatorialTestRunner.runCombined(
            values1: [nil, "", "   "],
            values2: ["", "   "]
        ) { loginUsername, cipherName in
            let subject = CipherView.fixture(
                login: LoginView.fixture(
                    username: loginUsername
                ),
                name: cipherName,
                type: .login
            )

            XCTAssertEqual(expected, subject.mainFido2CredentialUsername)
        }

        // empty Fido2 credentials
        CombinatorialTestRunner.runCombined(
            values1: [nil, "", "   "],
            values2: ["", "   "]
        ) { loginUsername, cipherName in
            let subject = CipherView.fixture(
                login: LoginView.fixture(
                    fido2Credentials: [],
                    username: loginUsername
                ),
                name: cipherName,
                type: .login
            )

            XCTAssertEqual(expected, subject.mainFido2CredentialUsername)
        }
    }
}
