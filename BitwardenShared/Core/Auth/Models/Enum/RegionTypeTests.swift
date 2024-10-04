import XCTest

@testable import BitwardenShared

class RegionTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(RegionType.europe.localizedName, Localizations.eu)
        XCTAssertEqual(RegionType.selfHosted.localizedName, Localizations.selfHosted)
        XCTAssertEqual(RegionType.unitedStates.localizedName, Localizations.us)
    }

    /// `getter:baseUrlDescription` returns the correct values.
    func test_baseUrlDescription() {
        XCTAssertEqual(RegionType.europe.baseUrlDescription, "bitwarden.eu")
        XCTAssertEqual(RegionType.selfHosted.baseUrlDescription, Localizations.selfHosted)
        XCTAssertEqual(RegionType.unitedStates.baseUrlDescription, "bitwarden.com")
    }

    /// `getter:defaultURLs` returns the correct values.
    func test_defaultURLs() {
        XCTAssertEqual(RegionType.europe.defaultURLs?.api?.absoluteString, "https://api.bitwarden.eu")
        XCTAssertNil(RegionType.selfHosted.defaultURLs)
        XCTAssertEqual(RegionType.unitedStates.defaultURLs?.api?.absoluteString, "https://api.bitwarden.com")
    }

    /// `getter:errorReporterName` returns the correct values.
    func test_errorReporterName() {
        XCTAssertEqual(RegionType.europe.errorReporterName, "EU")
        XCTAssertEqual(RegionType.selfHosted.errorReporterName, "Self-Hosted")
        XCTAssertEqual(RegionType.unitedStates.errorReporterName, "US")
    }
}
