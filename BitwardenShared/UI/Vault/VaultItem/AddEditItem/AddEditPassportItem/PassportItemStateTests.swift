import BitwardenSdk
import Foundation
import Testing

@testable import BitwardenShared

struct PassportItemStateTests {
    // MARK: Tests

    /// `passportView` maps every populated text and date field through to the SDK view,
    /// passing the raw ISO date strings through verbatim (no `Date` conversion in the model).
    @Test
    func passportView_populated() {
        let subject = PassportItemState(
            birthPlace: "USA",
            dateOfBirth: "2025-04-20",
            expirationDate: "2026-08-10",
            givenName: "Mitchell",
            issueDate: "2021-08-10",
            issuingAuthority: "U.S. Department of State",
            issuingCountry: "United States",
            nationalIdentificationNumber: "123456789",
            nationality: "USA",
            passportNumber: "X12345678",
            passportType: "Regular/Tourist",
            sex: "Male",
            surname: "Johnson",
        )

        let view = subject.passportView

        #expect(view.surname == "Johnson")
        #expect(view.givenName == "Mitchell")
        #expect(view.dateOfBirth == "2025-04-20")
        #expect(view.sex == "Male")
        #expect(view.birthPlace == "USA")
        #expect(view.nationality == "USA")
        #expect(view.issuingCountry == "United States")
        #expect(view.passportNumber == "X12345678")
        #expect(view.passportType == "Regular/Tourist")
        #expect(view.nationalIdentificationNumber == "123456789")
        #expect(view.issuingAuthority == "U.S. Department of State")
        #expect(view.issueDate == "2021-08-10")
        #expect(view.expirationDate == "2026-08-10")
    }

    /// `passportView` maps every empty field to `nil` via `.nilIfEmpty`.
    @Test
    func passportView_empty() {
        let subject = PassportItemState()

        let view = subject.passportView

        #expect(view.surname == nil)
        #expect(view.givenName == nil)
        #expect(view.dateOfBirth == nil)
        #expect(view.sex == nil)
        #expect(view.birthPlace == nil)
        #expect(view.nationality == nil)
        #expect(view.issuingCountry == nil)
        #expect(view.passportNumber == nil)
        #expect(view.passportType == nil)
        #expect(view.nationalIdentificationNumber == nil)
        #expect(view.issuingAuthority == nil)
        #expect(view.issueDate == nil)
        #expect(view.expirationDate == nil)
    }

    /// `passportView` passes raw ISO date strings through verbatim, mapping empty dates to `nil`.
    @Test
    func passportView_dateStringsPassThroughVerbatim() {
        var subject = PassportItemState()
        subject.dateOfBirth = "2025-04-20"
        subject.issueDate = "2021-08-10"
        subject.expirationDate = ""

        let view = subject.passportView

        #expect(view.dateOfBirth == "2025-04-20")
        #expect(view.issueDate == "2021-08-10")
        #expect(view.expirationDate == nil)
    }

    /// `dateOfBirthDisplay` formats a valid ISO date-only string as a long localized date and
    /// returns an empty string when unset.
    @Test
    func dateOfBirthDisplay() throws {
        var subject = PassportItemState()

        #expect(subject.dateOfBirthDisplay.isEmpty)

        subject.dateOfBirth = "2025-04-20"
        let expectedDate = try utcDate("2025-04-20")
        #expect(subject.dateOfBirthDisplay == expectedDate.formatted(date: .long, time: .omitted))
        #expect(subject.dateOfBirthDisplay.contains("April"))
        #expect(subject.dateOfBirthDisplay.contains("2025"))
    }

    /// `dateOfBirthDisplay` returns an empty string for an unparsable date string.
    @Test
    func dateOfBirthDisplay_unparsable() {
        var subject = PassportItemState()
        subject.dateOfBirth = "not-a-date"

        #expect(subject.dateOfBirthDisplay.isEmpty)
    }

    /// `issueDateDisplay` formats a valid ISO date-only string as a long localized date and
    /// returns an empty string when unset.
    @Test
    func issueDateDisplay() throws {
        var subject = PassportItemState()

        #expect(subject.issueDateDisplay.isEmpty)

        subject.issueDate = "2021-08-10"
        let expectedDate = try utcDate("2021-08-10")
        #expect(subject.issueDateDisplay == expectedDate.formatted(date: .long, time: .omitted))
        #expect(subject.issueDateDisplay.contains("August"))
    }

    /// `expirationDateDisplay` formats a valid ISO date-only string as a long localized date and
    /// returns an empty string when unset.
    @Test
    func expirationDateDisplay() throws {
        var subject = PassportItemState()

        #expect(subject.expirationDateDisplay.isEmpty)

        subject.expirationDate = "2026-08-10"
        let expectedDate = try utcDate("2026-08-10")
        #expect(subject.expirationDateDisplay == expectedDate.formatted(date: .long, time: .omitted))
        #expect(subject.expirationDateDisplay.contains("August"))
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
