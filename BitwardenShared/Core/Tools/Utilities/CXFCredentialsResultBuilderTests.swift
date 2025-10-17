import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - CXFCredentialsResultBuilderTests

class CXFCredentialsResultBuilderTests: BitwardenTestCase {
    // MARK: Properties

    var subject: CXFCredentialsResultBuilder!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DefaultCXFCredentialsResultBuilder()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `build(from:)` returns the credentials results from the ciphers passed.
    func test_build() {
        let ciphers: [Cipher] = [
            .fixture(type: .login),
            .fixture(type: .card),
            .fixture(type: .card),
            .fixture(type: .identity),
            .fixture(type: .secureNote),
            .fixture(type: .identity),
            .fixture(type: .card),
            .fixture(type: .sshKey),
            .fixture(type: .login),
            .fixture(
                login: .fixture(
                    fido2Credentials: [
                        .fixture(),
                    ],
                ),
                type: .login,
            ),
        ]
        let result = subject.build(from: ciphers)
        XCTAssertEqual(result.count, 6)
        XCTAssertEqual(result[0].type, .password)
        XCTAssertEqual(result[0].count, 2)
        XCTAssertEqual(result[1].type, .passkey)
        XCTAssertEqual(result[1].count, 1)
        XCTAssertEqual(result[2].type, .card)
        XCTAssertEqual(result[2].count, 3)
        XCTAssertEqual(result[3].type, .identity)
        XCTAssertEqual(result[3].count, 2)
        XCTAssertEqual(result[4].type, .secureNote)
        XCTAssertEqual(result[4].count, 1)
        XCTAssertEqual(result[5].type, .sshKey)
        XCTAssertEqual(result[5].count, 1)
    }
}
