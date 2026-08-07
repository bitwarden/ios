import BitwardenKit
import BitwardenSdk
import Foundation
import Testing

@testable import BitwardenShared

struct DriversLicenseItemStateTests {
    // MARK: Tests

    /// `driversLicenseView` maps every populated field through to the SDK view.
    @Test
    func driversLicenseView_populated() {
        let subject = DriversLicenseItemState(
            dateOfBirth: Date(year: 1989, month: 8, day: 1),
            expirationDate: Date(year: 2029, month: 8, day: 1),
            firstName: "Bit",
            issueDate: Date(year: 2019, month: 8, day: 1),
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
        #expect(view.dateOfBirth == Date(year: 1989, month: 8, day: 1))
        #expect(view.licenseNumber == "D1234567")
        #expect(view.issuingCountry == "United States")
        #expect(view.issuingState == "California")
        #expect(view.issueDate == Date(year: 2019, month: 8, day: 1))
        #expect(view.expirationDate == Date(year: 2029, month: 8, day: 1))
        #expect(view.issuingAuthority == "DMV")
        #expect(view.licenseClass == "C")
    }

    /// `driversLicenseView` maps every empty/unset field to `nil`.
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

    /// `dateOfBirthDisplay` formats a set date as a long localized date and returns an empty string
    /// when unset.
    @Test
    func dateOfBirthDisplay() {
        var subject = DriversLicenseItemState()

        #expect(subject.dateOfBirthDisplay.isEmpty)

        subject.dateOfBirth = Date(year: 2026, month: 8, day: 10)
        #expect(subject.dateOfBirthDisplay == subject.dateOfBirth?.longCalendarDateDisplay)
        #expect(subject.dateOfBirthDisplay.contains("August"))
        #expect(subject.dateOfBirthDisplay.contains("2026"))
    }

    /// `expirationDateDisplay` formats a set date as a long localized date and returns an empty
    /// string when unset.
    @Test
    func expirationDateDisplay() {
        var subject = DriversLicenseItemState()

        #expect(subject.expirationDateDisplay.isEmpty)

        subject.expirationDate = Date(year: 2029, month: 1, day: 5)
        #expect(subject.expirationDateDisplay == subject.expirationDate?.longCalendarDateDisplay)
        #expect(subject.expirationDateDisplay.contains("January"))
    }

    /// `issueDateDisplay` formats a set date as a long localized date and returns an empty string
    /// when unset.
    @Test
    func issueDateDisplay() {
        var subject = DriversLicenseItemState()

        #expect(subject.issueDateDisplay.isEmpty)

        subject.issueDate = Date(year: 2019, month: 8, day: 1)
        #expect(subject.issueDateDisplay == subject.issueDate?.longCalendarDateDisplay)
        #expect(subject.issueDateDisplay.contains("August"))
    }

    /// `dateOfBirthDisplay` shows the same calendar day the user picked in `DateFieldPicker`, even
    /// in a time zone behind UTC, where the UTC-anchored stored value falls on the previous day.
    @Test
    func dateOfBirthDisplay_matchesPickedDayInTimeZoneBehindUTC() {
        let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
        let pickedLocalDay = Date(year: 2026, month: 8, day: 10, timeZone: losAngeles)

        var subject = DriversLicenseItemState()
        subject.dateOfBirth = pickedLocalDay.asUTCCalendarDay(from: losAngeles)

        #expect(subject.dateOfBirthDisplay.contains("August"))
        #expect(subject.dateOfBirthDisplay.contains("10"))
        #expect(subject.dateOfBirthDisplay.contains("2026"))
        #expect(!subject.dateOfBirthDisplay.contains(" 9,"))
    }
}
