import BitwardenKit
import XCTest

import BitwardenResources
@testable import BitwardenShared

class RegionTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(RegionType.europe.localizedName, Localizations.eu)
        XCTAssertEqual(RegionType.internal.localizedName, "Internal")
        XCTAssertEqual(RegionType.selfHosted.localizedName, Localizations.selfHosted)
        XCTAssertEqual(RegionType.unitedStates.localizedName, Localizations.us)
    }

    /// `getter:baseURLDescription` returns the correct values.
    func test_baseURLDescription() {
        XCTAssertEqual(RegionType.europe.baseURLDescription, "bitwarden.eu")
        XCTAssertEqual(RegionType.internal.baseURLDescription, Localizations.selfHosted)
        XCTAssertEqual(RegionType.selfHosted.baseURLDescription, Localizations.selfHosted)
        XCTAssertEqual(RegionType.unitedStates.baseURLDescription, "bitwarden.com")
    }

    /// `getter:defaultURLs` returns the correct values.
    func test_defaultURLs() {
        XCTAssertEqual(RegionType.europe.defaultURLs?.api?.absoluteString, "https://api.bitwarden.eu")
        XCTAssertNil(RegionType.internal.defaultURLs)
        XCTAssertNil(RegionType.selfHosted.defaultURLs)
        XCTAssertEqual(RegionType.unitedStates.defaultURLs?.api?.absoluteString, "https://api.bitwarden.com")
    }

    /// `getter:errorReporterName` returns the correct values.
    func test_errorReporterName() {
        XCTAssertEqual(RegionType.europe.errorReporterName, "EU")
        XCTAssertEqual(RegionType.internal.errorReporterName, "Internal")
        XCTAssertEqual(RegionType.selfHosted.errorReporterName, "Self-Hosted")
        XCTAssertEqual(RegionType.unitedStates.errorReporterName, "US")
    }

    /// `getter:isUserSelectable` is true for the user-facing regions and false for internal.
    func test_isUserSelectable() {
        XCTAssertTrue(RegionType.europe.isUserSelectable)
        XCTAssertFalse(RegionType.internal.isUserSelectable)
        XCTAssertTrue(RegionType.selfHosted.isUserSelectable)
        XCTAssertTrue(RegionType.unitedStates.isUserSelectable)
    }

    /// `userSelectableCases` returns the user-facing regions in display order, excluding internal.
    func test_userSelectableCases() {
        XCTAssertEqual(RegionType.userSelectableCases, [.unitedStates, .europe, .selfHosted])
    }
}
