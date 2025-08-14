import BitwardenKit
import XCTest

import BitwardenResources
@testable import BitwardenShared

class RegionTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(RegionType.europe.localizedName, Localizations.eu)
        XCTAssertEqual(RegionType.selfHosted.localizedName, Localizations.selfHosted)
        XCTAssertEqual(RegionType.unitedStates.localizedName, Localizations.us)
    }

    /// `getter:baseURLDescription` returns the correct values.
    func test_baseURLDescription() {
        XCTAssertEqual(RegionType.europe.baseURLDescription, "bitwarden.eu")
        XCTAssertEqual(RegionType.selfHosted.baseURLDescription, Localizations.selfHosted)
        XCTAssertEqual(RegionType.unitedStates.baseURLDescription, "bitwarden.com")
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
