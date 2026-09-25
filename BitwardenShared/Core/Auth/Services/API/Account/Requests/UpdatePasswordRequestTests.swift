import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class UpdatePasswordRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: UpdatePasswordRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = UpdatePasswordRequest(
            requestModel: UpdatePasswordRequestModel(
                authenticationData: MasterPasswordAuthenticationDataRequestModel(
                    kdf: KdfConfig(),
                    masterPasswordAuthenticationHash: "NEW_MASTER_PASSWORD_HASH",
                    salt: "AUTHENTICATION_SALT",
                ),
                masterPasswordHash: "MASTER_PASSWORD_HASH",
                masterPasswordHint: "MASTER_PASSWORD_HINT",
                unlockData: MasterPasswordUnlockDataRequestModel(
                    kdf: KdfConfig(),
                    masterKeyWrappedUserKey: "KEY",
                    salt: "UNLOCK_SALT",
                ),
            ),
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` is the JSON encoded request model.
    func test_body() throws {
        let bodyData = try XCTUnwrap(subject.body?.encode())
        XCTAssertEqual(
            bodyData.prettyPrintedJson,
            """
            {
              "authenticationData" : {
                "kdf" : {
                  "iterations" : 600000,
                  "kdfType" : 0
                },
                "masterPasswordAuthenticationHash" : "NEW_MASTER_PASSWORD_HASH",
                "salt" : "AUTHENTICATION_SALT"
              },
              "masterPasswordHash" : "MASTER_PASSWORD_HASH",
              "masterPasswordHint" : "MASTER_PASSWORD_HINT",
              "unlockData" : {
                "kdf" : {
                  "iterations" : 600000,
                  "kdfType" : 0
                },
                "masterKeyWrappedUserKey" : "KEY",
                "salt" : "UNLOCK_SALT"
              }
            }
            """,
        )
    }

    /// `method` is `.post`.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` is the correct value.
    func test_path() {
        XCTAssertEqual(subject.path, "/accounts/password")
    }
}
