import BitwardenSdk
import Foundation
import Testing

@testable import BitwardenShared

struct PassportItemStateTests {
    // MARK: Tests

    /// `passportView` maps every populated field through to the SDK view.
    @Test
    func passportView_populated() {
        let subject = PassportItemState(
            birthPlace: "USA",
            dateOfBirth: Date(year: 2025, month: 4, day: 20),
            expirationDate: Date(year: 2026, month: 8, day: 10),
            givenName: "Mitchell",
            issueDate: Date(year: 2021, month: 8, day: 10),
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
        #expect(view.dateOfBirth == Date(year: 2025, month: 4, day: 20))
        #expect(view.sex == "Male")
        #expect(view.birthPlace == "USA")
        #expect(view.nationality == "USA")
        #expect(view.issuingCountry == "United States")
        #expect(view.passportNumber == "X12345678")
        #expect(view.passportType == "Regular/Tourist")
        #expect(view.nationalIdentificationNumber == "123456789")
        #expect(view.issuingAuthority == "U.S. Department of State")
        #expect(view.issueDate == Date(year: 2021, month: 8, day: 10))
        #expect(view.expirationDate == Date(year: 2026, month: 8, day: 10))
    }

    /// `passportView` maps every empty/unset field to `nil`.
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

    /// `dateOfBirthDisplay` formats a set date as a long localized date and returns an empty string
    /// when unset.
    @Test
    func dateOfBirthDisplay() {
        var subject = PassportItemState()

        #expect(subject.dateOfBirthDisplay.isEmpty)

        subject.dateOfBirth = Date(year: 2025, month: 4, day: 20)
        #expect(subject.dateOfBirthDisplay == subject.dateOfBirth?.formatted(date: .long, time: .omitted))
        #expect(subject.dateOfBirthDisplay.contains("April"))
        #expect(subject.dateOfBirthDisplay.contains("2025"))
    }

    /// `issueDateDisplay` formats a set date as a long localized date and returns an empty string
    /// when unset.
    @Test
    func issueDateDisplay() {
        var subject = PassportItemState()

        #expect(subject.issueDateDisplay.isEmpty)

        subject.issueDate = Date(year: 2021, month: 8, day: 10)
        #expect(subject.issueDateDisplay == subject.issueDate?.formatted(date: .long, time: .omitted))
        #expect(subject.issueDateDisplay.contains("August"))
    }

    /// `expirationDateDisplay` formats a set date as a long localized date and returns an empty
    /// string when unset.
    @Test
    func expirationDateDisplay() {
        var subject = PassportItemState()

        #expect(subject.expirationDateDisplay.isEmpty)

        subject.expirationDate = Date(year: 2026, month: 8, day: 10)
        #expect(subject.expirationDateDisplay == subject.expirationDate?.formatted(date: .long, time: .omitted))
        #expect(subject.expirationDateDisplay.contains("August"))
    }
}
