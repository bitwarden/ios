import XCTest

@testable import BitwardenShared

// MARK: - VaultListFilterTests

class VaultListFilterTests: BitwardenTestCase {
    // MARK: Tests

    /// `init` with default parameters initializes with expected values.
    func test_init_defaults() {
        let subject = VaultListFilter()

        XCTAssertEqual(subject.filterType, .allVaults)
        XCTAssertNil(subject.group)
        XCTAssertNil(subject.mode)
        XCTAssertEqual(subject.options, [])
        XCTAssertNil(subject.rpID)
        XCTAssertNil(subject.searchText)
        XCTAssertNil(subject.uri)
    }

    /// `init` with custom parameters initializes with expected values.
    func test_init_customParameters() {
        let subject = VaultListFilter(
            filterType: .myVault,
            group: .card,
            mode: .all,
            options: [.addTOTPGroup, .addHiddenItemsGroup],
            rpID: "example.com",
            searchText: "test",
            uri: "https://example.com",
        )

        XCTAssertEqual(subject.filterType, .myVault)
        XCTAssertEqual(subject.group, .card)
        XCTAssertEqual(subject.mode, .all)
        XCTAssertEqual(subject.options, [.addTOTPGroup, .addHiddenItemsGroup])
        XCTAssertEqual(subject.rpID, "example.com")
        XCTAssertEqual(subject.searchText, "test")
        XCTAssertEqual(subject.uri, "https://example.com")
    }

    /// `init` with `nil` search text sets `searchText` to `nil`.
    func test_init_searchText_nil() {
        let subject = VaultListFilter(searchText: nil)

        XCTAssertNil(subject.searchText)
    }

    /// `init` with empty search text sets `searchText` to empty string.
    func test_init_searchText_empty() {
        let subject = VaultListFilter(searchText: "")

        XCTAssertEqual(subject.searchText, "")
    }

    /// `init` with search text trims whitespace and newlines.
    func test_init_searchText_trimsWhitespaceAndNewlines() {
        let subject = VaultListFilter(searchText: "  \n test \n  ")

        XCTAssertEqual(subject.searchText, "test")
    }

    /// `init` with search text converts to lowercase.
    func test_init_searchText_lowercased() {
        let subject = VaultListFilter(searchText: "TeSt SeArCh")

        XCTAssertEqual(subject.searchText, "test search")
    }

    /// `init` with search text removes diacritics.
    func test_init_searchText_diacriticInsensitive() {
        let subject = VaultListFilter(searchText: "café")

        XCTAssertEqual(subject.searchText, "cafe")
    }

    /// `init` with search text applies all transformations: trim, lowercase, and diacritic removal.
    func test_init_searchText_allTransformations() {
        let subject = VaultListFilter(searchText: "  \n CaFé Niño \n  ")

        XCTAssertEqual(subject.searchText, "cafe nino")
    }

    /// `init` with search text containing only whitespace sets `searchText` to empty string.
    func test_init_searchText_onlyWhitespace() {
        let subject = VaultListFilter(searchText: "   \n\n   ")

        XCTAssertEqual(subject.searchText, "")
    }

    /// `init` with search text containing various diacritics removes them correctly.
    func test_init_searchText_variousDiacritics() {
        let subject = VaultListFilter(searchText: "àáâãäåèéêëìíîïòóôõöùúûü")

        XCTAssertEqual(subject.searchText, "aaaaaaeeeeiiiiooooouuuu")
    }

    /// `init` with search text containing non-Latin characters preserves them.
    func test_init_searchText_nonLatinCharacters() {
        let subject = VaultListFilter(searchText: "テスト")

        XCTAssertEqual(subject.searchText, "テスト")
    }

    /// `init` with search text containing special characters preserves them.
    func test_init_searchText_specialCharacters() {
        let subject = VaultListFilter(searchText: "test@123!#$%")

        XCTAssertEqual(subject.searchText, "test@123!#$%")
    }
}
