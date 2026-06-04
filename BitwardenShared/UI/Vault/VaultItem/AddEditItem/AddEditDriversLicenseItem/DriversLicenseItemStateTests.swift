import BitwardenSdk
import Foundation
import Testing

@testable import BitwardenShared

struct DriversLicenseItemStateTests {
    // MARK: Tests

    /// `driversLicenseView` maps every populated text and date field through to the SDK view,
    /// passing the raw ISO date strings through verbatim (no `Date` conversion in the model).
    @Test
    func driversLicenseView_populated() {
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

        #expect(view.firstName == "Bit")
        #expect(view.middleName == "W")
        #expect(view.lastName == "Warden")
        #expect(view.dateOfBirth == "1989-08-01")
        #expect(view.licenseNumber == "D1234567")
        #expect(view.issuingCountry == "United States")
        #expect(view.issuingState == "California")
        #expect(view.issueDate == "2019-08-01")
        #expect(view.expirationDate == "2029-08-01")
        #expect(view.issuingAuthority == "DMV")
        #expect(view.licenseClass == "C")
    }

    /// `driversLicenseView` maps every empty field to `nil` via `.nilIfEmpty`.
    @Test
    func driversLicenseView_empty() {
        let subject = DriversLicenseItemState()

        let view = subject.driversLicenseView

        #expect(view.firstName == nil)
        #expect(view.middleName == nil)
        #expect(view.lastName == nil)
        #expect(view.dateOfBirth == nil)
        #expect(view.licenseNumber == nil)
        #expect(view.issuingCountry == nil)
        #expect(view.issuingState == nil)
        #expect(view.issueDate == nil)
        #expect(view.expirationDate == nil)
        #expect(view.issuingAuthority == nil)
        #expect(view.licenseClass == nil)
    }

    /// `driversLicenseView` passes raw ISO date strings through verbatim without transformation,
    /// while still mapping empty date strings to `nil`.
    @Test
    func driversLicenseView_dateStringsPassThroughVerbatim() {
        var subject = DriversLicenseItemState()
        subject.dateOfBirth = "1989-08-01"
        subject.issueDate = "2019-12-31"
        subject.expirationDate = ""

        let view = subject.driversLicenseView

        #expect(view.dateOfBirth == "1989-08-01")
        #expect(view.issueDate == "2019-12-31")
        #expect(view.expirationDate == nil)
    }

    /// `dateOfBirthDisplay` formats a valid ISO date-only string as a long localized date and
    /// returns an empty string when unset.
    @Test
    func dateOfBirthDisplay() throws {
        var subject = DriversLicenseItemState()

        #expect(subject.dateOfBirthDisplay.isEmpty)

        subject.dateOfBirth = "2026-08-10"
        let expectedDate = try utcDate("2026-08-10")
        // Compare against the same `.formatted` render the source uses so the assertion is
        // deterministic regardless of the host time zone (both sides render in the same zone).
        #expect(subject.dateOfBirthDisplay == expectedDate.formatted(date: .long, time: .omitted))
        #expect(subject.dateOfBirthDisplay.contains("August"))
        #expect(subject.dateOfBirthDisplay.contains("2026"))
    }

    /// `dateOfBirthDisplay` returns an empty string for an unparsable date string.
    @Test
    func dateOfBirthDisplay_unparsable() {
        var subject = DriversLicenseItemState()
        subject.dateOfBirth = "not-a-date"

        #expect(subject.dateOfBirthDisplay.isEmpty)
    }

    /// `expirationDateDisplay` formats a valid ISO date-only string as a long localized date and
    /// returns an empty string when unset.
    @Test
    func expirationDateDisplay() throws {
        var subject = DriversLicenseItemState()

        #expect(subject.expirationDateDisplay.isEmpty)

        subject.expirationDate = "2029-01-05"
        let expectedDate = try utcDate("2029-01-05")
        #expect(subject.expirationDateDisplay == expectedDate.formatted(date: .long, time: .omitted))
        #expect(subject.expirationDateDisplay.contains("January"))
    }

    /// `issueDateDisplay` formats a valid ISO date-only string as a long localized date and
    /// returns an empty string when unset.
    @Test
    func issueDateDisplay() throws {
        var subject = DriversLicenseItemState()

        #expect(subject.issueDateDisplay.isEmpty)

        subject.issueDate = "2019-08-01"
        let expectedDate = try utcDate("2019-08-01")
        #expect(subject.issueDateDisplay == expectedDate.formatted(date: .long, time: .omitted))
        #expect(subject.issueDateDisplay.contains("August"))
    }

    // MARK: Helpers

    /// Parses a `yyyy-MM-dd` string as a UTC date, mirroring the source's display parser so
    /// expectations render in the same time zone as the value under test.
    private func utcDate(_ string: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return try #require(formatter.date(from: string))
    }
}
