import InlineSnapshotTesting
import XCTest

@testable import AuthenticatorShared

class AuthenticatorItemRepositoryTests: AuthenticatorTestCase {
    // MARK: Properties

    var authenticatorItemService: MockAuthenticatorItemService!
    var cryptographyService: MockCryptographyService!
    var subject: DefaultAuthenticatorItemRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authenticatorItemService = MockAuthenticatorItemService()
        cryptographyService = MockCryptographyService()

        subject = DefaultAuthenticatorItemRepository(
            authenticatorItemService: authenticatorItemService,
            cryptographyService: cryptographyService
        )
    }

    override func tearDown() {
        super.tearDown()

        authenticatorItemService = nil
        cryptographyService = nil
        subject = nil
    }

    // MARK: Tests

    /// `addAuthenticatorItem()` updates the items in storage
    func test_addAuthenticatorItem() async throws {
        let item = AuthenticatorItemView.fixture()
        try await subject.addAuthenticatorItem(item)

        XCTAssertEqual(cryptographyService.encryptedAuthenticatorItems, [item])
        XCTAssertEqual(
            authenticatorItemService.addAuthenticatorItemAuthenticatorItems.last,
            AuthenticatorItem(authenticatorItemView: item)
        )
    }

    /// `addAuthenticatorItem()` throws an error if encrypting the item fails
    func test_addAuthenticatorItem_encryptError() async {
        cryptographyService.encryptError = AuthenticatorTestError.example

        await assertAsyncThrows(error: AuthenticatorTestError.example) {
            try await subject.addAuthenticatorItem(.fixture())
        }
    }

    // TODO: Backfill tests
}
