import XCTest

@testable import AuthenticatorShared

// MARK: - ItemListItemTests

class ItemListItemTests: BitwardenTestCase {
    var subject: ItemListItem!

    func test_localizedNameComparator() {
        let alpha = ItemListItem.fixture(name: "alpha")
        let alphaCaps = ItemListItem.fixture(name: "ALPHA")
        let beta = ItemListItem.fixture(name: "beta")
        let blankNameAlpha = ItemListItem.fixture(name: "", accountName: "alpha")
        let blankBoth = ItemListItem.fixtureShared(name: "", accountName: nil)

        let expected = [blankBoth, alpha, blankNameAlpha, alphaCaps, beta]
        let list = [beta, alphaCaps, alpha, blankNameAlpha, blankBoth]

        XCTAssertEqual(list.sorted(by: ItemListItem.localizedNameComparator), expected)
    }

    /// `totpCodeModel` returns the associated `TOTPCodeModel` for an item of type `.sharedTotp`.
    func test_totpCodeModel_shared() {
        let expected = TOTPCodeModel(code: "098765", codeGenerationDate: .now, period: 30)
        subject = .fixtureShared(totp: .fixture(totpCode: expected))

        XCTAssertEqual(expected, subject.totpCodeModel)
    }

    /// `totpCodeModel` returns `nil` for an item of type `.syncError`.
    func test_totpCodeModel_syncError() {
        subject = .syncError()

        XCTAssertNil(subject.totpCodeModel)
    }

    /// `totpCodeModel` returns the associated `TOTPCodeModel` for an item of type `.totp`.
    func test_totpCodeModel_totp() {
        let expected = TOTPCodeModel(code: "098765", codeGenerationDate: .now, period: 30)
        subject = .fixture(totp: .fixture(totpCode: expected))

        XCTAssertEqual(expected, subject.totpCodeModel)
    }

    /// For the `.sharedTotp` case, `with(newTotpModel:)` returns a copy of the item with the new TOTP code.
    func test_withNewTotpModel_shared() {
        subject = .fixtureShared()
        let newModel = TOTPCodeModel(
            code: "098765",
            codeGenerationDate: Date(),
            period: 30,
        )

        let newItem = subject.with(newTotpModel: newModel)
        XCTAssertEqual(newItem.totpCodeModel, newModel)
    }

    /// For the `.syncError` case, `with(newTotpModel:)` simply returns a copy of the item.
    func test_withNewTotpModel_syncError() {
        subject = .syncError()
        let newModel = TOTPCodeModel(
            code: "098765",
            codeGenerationDate: Date(),
            period: 30,
        )

        let newItem = subject.with(newTotpModel: newModel)
        XCTAssertEqual(subject, newItem)
    }

    /// For the `.totp`case, `with(newTotpModel:)` returns a copy of the item with the new TOTP code.
    func test_withNewTotpModel_totp() {
        subject = .fixture()
        let newModel = TOTPCodeModel(
            code: "098765",
            codeGenerationDate: Date(),
            period: 30,
        )

        let newItem = subject.with(newTotpModel: newModel)
        XCTAssertEqual(newItem.totpCodeModel, newModel)
    }
}
