import XCTest

@testable import BitwardenShared

class UpdateKdfRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: UpdateKdfRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = UpdateKdfRequest(
            requestModel: UpdateKdfRequestModel(
                authenticationData: MasterPasswordAuthenticationDataRequestModel(
                    kdf: KdfConfig(
                        kdfType: .argon2id,
                        iterations: 3,
                        memory: 64,
                        parallelism: 4,
                    ),
                    masterPasswordAuthenticationHash: "MASTER_PASSWORD_AUTHENTICATION_HASH",
                    salt: "AUTHENTICATION_SALT",
                ),
                key: "key",
                masterPasswordHash: "MASTER_PASSWORD_HASH",
                newMasterPasswordHash: "NEW_MASTER_PASSWORD_HINT",
                unlockData: MasterPasswordUnlockDataRequestModel(
                    kdf: KdfConfig(),
                    masterKeyWrappedUserKey: "MASTER_KEY_WRAPPED_USER_KEY",
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
                  "iterations" : 3,
                  "kdfType" : 1,
                  "memory" : 64,
                  "parallelism" : 4
                },
                "masterPasswordAuthenticationHash" : "MASTER_PASSWORD_AUTHENTICATION_HASH",
                "salt" : "AUTHENTICATION_SALT"
              },
              "key" : "key",
              "masterPasswordHash" : "MASTER_PASSWORD_HASH",
              "newMasterPasswordHash" : "NEW_MASTER_PASSWORD_HINT",
              "unlockData" : {
                "kdf" : {
                  "iterations" : 600000,
                  "kdfType" : 0
                },
                "masterKeyWrappedUserKey" : "MASTER_KEY_WRAPPED_USER_KEY",
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
        XCTAssertEqual(subject.path, "/accounts/kdf")
    }
}
