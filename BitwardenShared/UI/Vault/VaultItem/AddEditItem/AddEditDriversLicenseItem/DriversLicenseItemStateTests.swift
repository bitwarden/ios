import BitwardenSdk
import XCTest

@testable import BitwardenShared

class DriversLicenseItemStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `driversLicenseView` maps every populated text and date field through to the SDK view,
    /// passing the raw ISO date strings through verbatim (no `Date` conversion in the model).
    func test_driversLicenseView_populated() {
        let subject = DriversLicenseItemState(
            dateOfBirth: "1989-08-01",
            expirationDate: "2029-08-01",
            firstName: "Bit",
            issueDate: "2019-08-01",
            issuingAuthority: "DMV",
            issuingCountry: "United States",
            issuingState: "California",
            lastName: "Warden",
            licenseClass: "C",
            licenseNumber: "D1234567",
            middleName: "W",
        )

        let view = subject.driversLicenseView

        XCTAssertEqual(view.firstName, "Bit")
        XCTAssertEqual(view.middleName, "W")
        XCTAssertEqual(view.lastName, "Warden")
        XCTAssertEqual(view.dateOfBirth, "1989-08-01")
        XCTAssertEqual(view.licenseNumber, "D1234567")
        XCTAssertEqual(view.issuingCountry, "United States")
        XCTAssertEqual(view.issuingState, "California")
        XCTAssertEqual(view.issueDate, "2019-08-01")
        XCTAssertEqual(view.expirationDate, "2029-08-01")
        XCTAssertEqual(view.issuingAuthority, "DMV")
        XCTAssertEqual(view.licenseClass, "C")
    }

    /// `driversLicenseView` maps every empty field to `nil` via `.nilIfEmpty`.
    func test_driversLicenseView_empty() {
        let subject = DriversLicenseItemState()

        let view = subject.driversLicenseView

        XCTAssertNil(view.firstName)
        XCTAssertNil(view.middleName)
        XCTAssertNil(view.lastName)
        XCTAssertNil(view.dateOfBirth)
        XCTAssertNil(view.licenseNumber)
        XCTAssertNil(view.issuingCountry)
        XCTAssertNil(view.issuingState)
        XCTAssertNil(view.issueDate)
        XCTAssertNil(view.expirationDate)
        XCTAssertNil(view.issuingAuthority)
        XCTAssertNil(view.licenseClass)
    }

    /// `driversLicenseView` passes raw ISO date strings through verbatim without transformation,
    /// while still mapping empty date strings to `nil`.
    func test_driversLicenseView_dateStringsPassThroughVerbatim() {
        var subject = DriversLicenseItemState()
        subject.dateOfBirth = "1989-08-01"
        subject.issueDate = "2019-12-31"
        subject.expirationDate = ""

        let view = subject.driversLicenseView

        XCTAssertEqual(view.dateOfBirth, "1989-08-01")
        XCTAssertEqual(view.issueDate, "2019-12-31")
        XCTAssertNil(view.expirationDate)
    }

    /// `dateOfBirthDisplay` formats a valid ISO date-only string as a long localized date and
    /// returns an empty string when unset.
    func test_dateOfBirthDisplay() throws {
        var subject = DriversLicenseItemState()

        XCTAssertEqual(subject.dateOfBirthDisplay, "")

        subject.dateOfBirth = "2026-08-10"
        let expectedDate = try utcDate("2026-08-10")
        // Compare against the same `.formatted` render the source uses so the assertion is
        // deterministic regardless of the host time zone (both sides render in the same zone).
        XCTAssertEqual(subject.dateOfBirthDisplay, expectedDate.formatted(date: .long, time: .omitted))
        XCTAssertTrue(subject.dateOfBirthDisplay.contains("August"))
        XCTAssertTrue(subject.dateOfBirthDisplay.contains("2026"))
    }

    /// `dateOfBirthDisplay` returns an empty string for an unparsable date string.
    func test_dateOfBirthDisplay_unparsable() {
        var subject = DriversLicenseItemState()
        subject.dateOfBirth = "not-a-date"

        XCTAssertEqual(subject.dateOfBirthDisplay, "")
    }

    /// `expirationDateDisplay` formats a valid ISO date-only string as a long localized date and
    /// returns an empty string when unset.
    func test_expirationDateDisplay() throws {
        var subject = DriversLicenseItemState()

        XCTAssertEqual(subject.expirationDateDisplay, "")

        subject.expirationDate = "2029-01-05"
        let expectedDate = try utcDate("2029-01-05")
        XCTAssertEqual(subject.expirationDateDisplay, expectedDate.formatted(date: .long, time: .omitted))
        XCTAssertTrue(subject.expirationDateDisplay.contains("January"))
    }

    /// `issueDateDisplay` formats a valid ISO date-only string as a long localized date and
    /// returns an empty string when unset.
    func test_issueDateDisplay() throws {
        var subject = DriversLicenseItemState()

        XCTAssertEqual(subject.issueDateDisplay, "")

        subject.issueDate = "2019-08-01"
        let expectedDate = try utcDate("2019-08-01")
        XCTAssertEqual(subject.issueDateDisplay, expectedDate.formatted(date: .long, time: .omitted))
        XCTAssertTrue(subject.issueDateDisplay.contains("August"))
    }

    // MARK: Helpers

    /// Parses a `yyyy-MM-dd` string as a UTC date, mirroring the source's display parser so
    /// expectations render in the same time zone as the value under test.
    private func utcDate(_ string: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return try XCTUnwrap(formatter.date(from: string))
    }
}
