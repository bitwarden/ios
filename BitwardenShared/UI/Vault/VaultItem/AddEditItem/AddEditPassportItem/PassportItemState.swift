import BitwardenSdk

// MARK: - PassportItemState

/// A model for a passport item.
///
struct PassportItemState: Equatable {
    /// The place of birth on the passport.
    var birthPlace: String = ""

    /// The date of birth on the passport, held as a raw ISO string.
    var dateOfBirth: String = ""

    /// The expiration date of the passport, held as a raw ISO string.
    var expirationDate: String = ""

    /// The given name (first name) on the passport.
    var givenName: String = ""

    /// Whether the national identification number is visible.
    var isNationalIdentificationNumberVisible: Bool = false

    /// Whether the passport number is visible.
    var isPassportNumberVisible: Bool = false

    /// The issue date of the passport, held as a raw ISO string.
    var issueDate: String = ""

    /// The authority/office that issued the passport.
    var issuingAuthority: String = ""

    /// The country that issued the passport.
    var issuingCountry: String = ""

    /// The national identification number on the passport.
    var nationalIdentificationNumber: String = ""

    /// The nationality on the passport.
    var nationality: String = ""

    /// The passport number.
    var passportNumber: String = ""

    /// The type of passport.
    var passportType: String = ""

    /// The sex on the passport.
    var sex: String = ""

    /// The surname (last name) on the passport.
    var surname: String = ""
}

extension PassportItemState {
    var passportView: PassportView {
        .init(
            surname: surname.nilIfEmpty,
            givenName: givenName.nilIfEmpty,
            dateOfBirth: dateOfBirth.nilIfEmpty,
            sex: sex.nilIfEmpty,
            birthPlace: birthPlace.nilIfEmpty,
            nationality: nationality.nilIfEmpty,
            issuingCountry: issuingCountry.nilIfEmpty,
            passportNumber: passportNumber.nilIfEmpty,
            passportType: passportType.nilIfEmpty,
            nationalIdentificationNumber: nationalIdentificationNumber.nilIfEmpty,
            issuingAuthority: issuingAuthority.nilIfEmpty,
            issueDate: issueDate.nilIfEmpty,
            expirationDate: expirationDate.nilIfEmpty,
        )
    }
}

// MARK: AddEditPassportItemState

extension PassportItemState: AddEditPassportItemState {}
