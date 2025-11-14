import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - CipherListViewExtensionsTests

class CipherListViewExtensionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `canBeUsedInBasicLoginAutofill` returns `false` when the cipher is not a login type.
    func test_canBeUsedInBasicLoginAutofill_nonLoginType() {
        XCTAssertFalse(CipherListView.fixture(type: .card(.fixture())).canBeUsedInBasicLoginAutofill)
        XCTAssertFalse(CipherListView.fixture(type: .identity).canBeUsedInBasicLoginAutofill)
        XCTAssertFalse(CipherListView.fixture(type: .secureNote).canBeUsedInBasicLoginAutofill)
        XCTAssertFalse(CipherListView.fixture(type: .sshKey).canBeUsedInBasicLoginAutofill)
    }

    /// `canBeUsedInBasicLoginAutofill` returns `false` when the login has no copyable login fields.
    func test_canBeUsedInBasicLoginAutofill_noLoginFields() {
        XCTAssertFalse(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `canBeUsedInBasicLoginAutofill` returns `false` when the login has only non-login copyable fields.
    func test_canBeUsedInBasicLoginAutofill_onlyNonLoginFields() {
        XCTAssertFalse(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.cardNumber, .cardSecurityCode],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `canBeUsedInBasicLoginAutofill` returns `true` when the login has a username field.
    func test_canBeUsedInBasicLoginAutofill_hasUsername() {
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.loginUsername],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `canBeUsedInBasicLoginAutofill` returns `true` when the login has a password field.
    func test_canBeUsedInBasicLoginAutofill_hasPassword() {
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.loginPassword],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `canBeUsedInBasicLoginAutofill` returns `true` when the login has a TOTP field.
    func test_canBeUsedInBasicLoginAutofill_hasTotp() {
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.loginTotp],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `canBeUsedInBasicLoginAutofill` returns `true` when the login has multiple login fields.
    func test_canBeUsedInBasicLoginAutofill_hasMultipleLoginFields() {
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.loginUsername, .loginPassword, .loginTotp],
            ).canBeUsedInBasicLoginAutofill,
        )
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.loginUsername, .loginPassword],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `canBeUsedInBasicLoginAutofill` returns `true` when the login has login fields mixed with other fields.
    func test_canBeUsedInBasicLoginAutofill_hasLoginFieldsWithOtherFields() {
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.loginUsername, .cardNumber],
            ).canBeUsedInBasicLoginAutofill,
        )
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.cardSecurityCode, .loginPassword, .identityUsername],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `passesRestrictItemTypesPolicy(_:)` passes the policy when there are no organization IDs.
    func test_passesRestrictItemTypesPolicy_noOrgIds() {
        XCTAssertTrue(CipherListView.fixture().passesRestrictItemTypesPolicy([]))
    }

    /// `passesRestrictItemTypesPolicy(_:)` passes the policy when the cipher type is not `.card`.
    func test_passesRestrictItemTypesPolicy_noCardType() {
        XCTAssertTrue(CipherListView.fixture(type: .login(.fixture())).passesRestrictItemTypesPolicy(["1"]))
        XCTAssertTrue(CipherListView.fixture(type: .identity).passesRestrictItemTypesPolicy(["1"]))
        XCTAssertTrue(CipherListView.fixture(type: .secureNote).passesRestrictItemTypesPolicy(["1"]))
        XCTAssertTrue(CipherListView.fixture(type: .sshKey).passesRestrictItemTypesPolicy(["1"]))
    }

    /// `passesRestrictItemTypesPolicy(_:)` doesn't pass the policy when there are organization IDs,
    /// cipher type is `.card` but cipher doesn't belong to an organization or such organization has empty ID.
    func test_passesRestrictItemTypesPolicy_noCipherOrganizationId() {
        XCTAssertFalse(
            CipherListView.fixture(organizationId: nil, type: .card(.fixture())).passesRestrictItemTypesPolicy(["1"]),
        )
        XCTAssertFalse(
            CipherListView.fixture(organizationId: "", type: .card(.fixture())).passesRestrictItemTypesPolicy(["1"]),
        )
    }

    /// `passesRestrictItemTypesPolicy(_:)` doesn't pass the policy when there are organization IDs,
    /// cipher type is `.card`, cipher belongs to an organization but it's part of the restricted IDs.
    func test_passesRestrictItemTypesPolicy_restrictedOrganizationId() {
        XCTAssertFalse(
            CipherListView.fixture(organizationId: "2", type: .card(.fixture()))
                .passesRestrictItemTypesPolicy(["1", "2", "3"]),
        )
    }

    /// `passesRestrictItemTypesPolicy(_:)` pass the policy when there are organization IDs,
    /// cipher type is `.card`, cipher belongs to an organization that isn't part of the restricted IDs.
    func test_passesRestrictItemTypesPolicy_passOnNonRestrictedOrganizationId() {
        XCTAssertTrue(
            CipherListView.fixture(organizationId: "5", type: .card(.fixture()))
                .passesRestrictItemTypesPolicy(["1", "2", "3"]),
        )
    }
}
