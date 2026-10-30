import XCTest

@testable import BitwardenShared

class UpdateTempPasswordRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: UpdateTempPasswordRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = UpdateTempPasswordRequest(
            requestModel: UpdateTempPasswordRequestModel(
                authenticationData: MasterPasswordAuthenticationDataRequestModel(
                    kdf: KdfConfig(),
                    masterPasswordAuthenticationHash: "NEW_MASTER_PASSWORD_HASH",
                    salt: "AUTHENTICATION_SALT",
                ),
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

    /// `method` is `.put`.
    func test_method() {
        XCTAssertEqual(subject.method, .put)
    }

    /// `path` is the correct value.
    func test_path() {
        XCTAssertEqual(subject.path, "/accounts/update-temp-password")
    }
}
