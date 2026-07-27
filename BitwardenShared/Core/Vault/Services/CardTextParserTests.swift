import Testing

@testable import BitwardenShared

// MARK: - CardTextParserTests

struct CardTextParserTests {
    // MARK: Properties

    let subject: DefaultCardTextParser

    // MARK: Setup

    init() {
        subject = DefaultCardTextParser()
    }

    // MARK: Tests – Card Number

    /// `parseCard(lines:)` extracts card numbers across formats including
    /// unseparated digits, space-separated, dash-separated, multi-segment lines,
    /// and various card network lengths (Visa, Amex, Discover).
    @Test(arguments: zip(
        [
            ["4111111111111111"],
            ["4111 1111 1111 1111"],
            ["4111-1111-1111-1111"],
            ["378282246310005"],
            ["4012888888881"],
            ["6011000000000000001"],
            ["4111", "1111", "1111", "1111"],
            ["3782", "822463", "10005"],
            ["4111111111111111", "1234"],
        ],
        [
            "4111111111111111",
            "4111111111111111",
            "4111111111111111",
            "378282246310005",
            "4012888888881",
            "6011000000000000001",
            "4111111111111111",
            "378282246310005",
            "4111111111111111",
        ],
    ))
    func parseCard_extractsCardNumber(lines: [String], expectedNumber: String) {
        let result = subject.parseCard(lines: lines)
        #expect(result.cardNumber == expectedNumber)
    }

    /// `parseCard(lines:)` returns nil for the card number when input lacks a recognizable card number pattern.
    @Test(arguments: [
        ["12282028"],
        ["JANE DOE", "12/28"],
    ])
    func parseCard_returnsNilCardNumber(lines: [String]) {
        let result = subject.parseCard(lines: lines)
        #expect(result.cardNumber == nil)
    }

    // MARK: Tests – Expiry

    /// `parseCard(lines:)` extracts expiry dates from short (MM/YY) and full (MM/YYYY)
    /// formats, including single-digit months and lines containing multiple dates.
    @Test(arguments: zip(
        [["12/28"], ["03/2031"], ["1/29"], ["01/20  12/28"]],
        [(12, "2028"), (3, "2031"), (1, "2029"), (12, "2028")],
    ))
    func parseCard_extractsExpiry(lines: [String], expected: (Int, String)) {
        let (expectedMonth, expectedYear) = expected
        let result = subject.parseCard(lines: lines)
        #expect(result.expirationMonth == expectedMonth)
        #expect(result.expirationYear == expectedYear)
    }

    /// `parseCard(lines:)` returns nil for both expiry fields when input contains no expiry date.
    @Test
    func parseCard_noExpiry() {
        let result = subject.parseCard(lines: ["4111111111111111"])
        #expect(result.expirationMonth == nil)
        #expect(result.expirationYear == nil)
    }

    // MARK: Tests – Edge Cases

    /// `parseCard(lines:)` returns nil for all fields when given an empty lines array.
    @Test
    func parseCard_emptyInput() {
        let result = subject.parseCard(lines: [])
        #expect(result.cardNumber == nil)
        #expect(result.expirationMonth == nil)
        #expect(result.expirationYear == nil)
    }

    /// `parseCard(lines:)` splits embedded newline characters within a single line element
    /// so each sub-line is parsed independently.
    @Test
    func parseCard_flattensEmbeddedNewlines() {
        let result = subject.parseCard(lines: ["4111111111111111\nJANE DOE\n12/28"])
        #expect(result.cardNumber == "4111111111111111")
        #expect(result.expirationMonth == 12)
    }

    /// `parseCard(lines:)` ignores blank and whitespace-only lines, leaving meaningful lines unaffected.
    @Test
    func parseCard_discardsWhitespaceOnlyLines() {
        let result = subject.parseCard(lines: ["   ", "", "4111111111111111"])
        #expect(result.cardNumber == "4111111111111111")
    }

    /// `parseCard(lines:)` correctly parses a realistic scan result containing a
    /// space-formatted card number, cardholder name, and expiry on separate lines.
    @Test
    func parseCard_realisticScan_cardNumberAndExpiry() {
        let lines = [
            "4111 1111 1111 1111",
            "JANE DOE",
            "12/28",
        ]
        let result = subject.parseCard(lines: lines)
        #expect(result.cardNumber == "4111111111111111")
        #expect(result.expirationMonth == 12)
        #expect(result.expirationYear == "2028")
    }

    // MARK: Tests – Luhn + Brand-Length Validation

    /// `parseCard(lines:)` rejects a 16-digit Visa-length number that fails the Luhn checksum.
    @Test
    func parseCard_luhnInvalid_rejectsCardNumber() {
        // 4111111111111112 differs from the valid test card by one digit — Luhn sum becomes 41.
        let result = subject.parseCard(lines: ["4111111111111112"])
        #expect(result.cardNumber == nil)
    }

    /// `parseCard(lines:)` rejects a 16-digit number whose leading digits identify it as Amex
    /// (expected length 15), even though it passes the Luhn checksum.
    @Test
    func parseCard_brandLengthMismatch_rejectsAmexWith16Digits() {
        // 3400000000000000: starts with 34 (Amex prefix), 16 digits, Luhn sum = 10 ✓.
        let result = subject.parseCard(lines: ["3400000000000000"])
        #expect(result.cardNumber == nil)
    }

    /// `parseCard(lines:)` accepts a valid 14-digit Diners Club number.
    @Test
    func parseCard_validDinersClub_extractsCardNumber() {
        // 30569309025904: standard Diners test card, 14 digits, Luhn sum = 50 ✓.
        let result = subject.parseCard(lines: ["30569309025904"])
        #expect(result.cardNumber == "30569309025904")
    }

    /// `parseCard(lines:)` accepts a Luhn-valid number whose brand is unrecognised,
    /// provided its length falls within the generic 13–19 digit range.
    @Test
    func parseCard_unknownBrandLuhnValid_extractsCardNumber() {
        // 9400000000003: 13 digits, prefix 94 → .other, Luhn sum = 20 ✓.
        let result = subject.parseCard(lines: ["9400000000003"])
        #expect(result.cardNumber == "9400000000003")
    }
}
