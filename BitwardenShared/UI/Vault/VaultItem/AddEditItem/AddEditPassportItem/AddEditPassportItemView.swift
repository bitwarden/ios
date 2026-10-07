import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - AddEditPassportItemView

/// A view that allows the user to add or edit a passport item for a vault.
///
struct AddEditPassportItemView: View {
    // MARK: Types

    /// The focusable fields in the passport view.
    enum FocusedField: Int, Hashable {
        case givenName
        case surname
        case sex
        case birthPlace
        case nationality
        case passportNumber
        case passportType
        case nationalIdentificationNumber
        case issuingCountry
        case issuingAuthority
    }

    // MARK: Properties

    /// The currently focused field.
    @FocusState private var focusedField: FocusedField?

    /// The `Store` for this view.
    @ObservedObject var store: Store<
        any AddEditPassportItemState,
        AddEditPassportItemAction,
        AddEditItemEffect,
    >

    var body: some View {
        SectionView(Localizations.passportDetails, contentSpacing: 8) {
            ContentBlock {
                BitwardenTextField(
                    title: Localizations.firstName,
                    text: store.binding(
                        get: \.givenName,
                        send: AddEditPassportItemAction.givenNameChanged,
                    ),
                    accessibilityIdentifier: "PassportFirstNameEntry",
                    focus: .field($focusedField, equals: .givenName),
                )
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.lastName,
                    text: store.binding(
                        get: \.surname,
                        send: AddEditPassportItemAction.surnameChanged,
                    ),
                    accessibilityIdentifier: "PassportLastNameEntry",
                    focus: .field($focusedField, equals: .surname),
                )
                .onSubmit { focusNextField($focusedField) }

                DateFieldPicker(
                    title: Localizations.dateOfBirth,
                    accessibilityIdentifier: "PassportDateOfBirthEntry",
                    date: store.binding(
                        get: \.dateOfBirth,
                        send: AddEditPassportItemAction.dateOfBirthChanged,
                    ),
                    in: Date.distantPast ... Date().asUTCCalendarDay(),
                )

                BitwardenTextField(
                    title: Localizations.sex,
                    text: store.binding(
                        get: \.sex,
                        send: AddEditPassportItemAction.sexChanged,
                    ),
                    accessibilityIdentifier: "PassportSexEntry",
                    focus: .field($focusedField, equals: .sex),
                )
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.birthPlace,
                    text: store.binding(
                        get: \.birthPlace,
                        send: AddEditPassportItemAction.birthPlaceChanged,
                    ),
                    accessibilityIdentifier: "PassportBirthPlaceEntry",
                    focus: .field($focusedField, equals: .birthPlace),
                )
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.nationality,
                    text: store.binding(
                        get: \.nationality,
                        send: AddEditPassportItemAction.nationalityChanged,
                    ),
                    accessibilityIdentifier: "PassportNationalityEntry",
                    focus: .field($focusedField, equals: .nationality),
                )
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.passportNumber,
                    text: store.binding(
                        get: \.passportNumber,
                        send: AddEditPassportItemAction.passportNumberChanged,
                    ),
                    accessibilityIdentifier: "PassportNumberEntry",
                    passwordVisibilityAccessibilityId: "ShowPassportNumberButton",
                    focus: .field($focusedField, equals: .passportNumber),
                    isPasswordVisible: store.binding(
                        get: \.isPassportNumberVisible,
                        send: AddEditPassportItemAction.togglePassportNumberVisibilityChanged,
                    ),
                )
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.passportType,
                    text: store.binding(
                        get: \.passportType,
                        send: AddEditPassportItemAction.passportTypeChanged,
                    ),
                    accessibilityIdentifier: "PassportTypeEntry",
                    focus: .field($focusedField, equals: .passportType),
                )
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.nationalIdentificationNumber,
                    text: store.binding(
                        get: \.nationalIdentificationNumber,
                        send: AddEditPassportItemAction.nationalIdentificationNumberChanged,
                    ),
                    accessibilityIdentifier: "PassportNationalIdentificationNumberEntry",
                    passwordVisibilityAccessibilityId: "ShowPassportNationalIdentificationNumberButton",
                    focus: .field($focusedField, equals: .nationalIdentificationNumber),
                    isPasswordVisible: store.binding(
                        get: \.isNationalIdentificationNumberVisible,
                        send: AddEditPassportItemAction.toggleNationalIdentificationNumberVisibilityChanged,
                    ),
                )
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.issuingCountry,
                    text: store.binding(
                        get: \.issuingCountry,
                        send: AddEditPassportItemAction.issuingCountryChanged,
                    ),
                    accessibilityIdentifier: "PassportIssuingCountryEntry",
                    focus: .field($focusedField, equals: .issuingCountry),
                )
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.issuingAuthorityOffice,
                    text: store.binding(
                        get: \.issuingAuthority,
                        send: AddEditPassportItemAction.issuingAuthorityChanged,
                    ),
                    accessibilityIdentifier: "PassportIssuingAuthorityEntry",
                    focus: .field($focusedField, equals: .issuingAuthority),
                )
                .onSubmit { focusNextField($focusedField) }

                DateFieldPicker(
                    title: Localizations.issueDate,
                    accessibilityIdentifier: "PassportIssueDateEntry",
                    date: store.binding(
                        get: \.issueDate,
                        send: AddEditPassportItemAction.issueDateChanged,
                    ),
                    in: Date.distantPast ... Date().asUTCCalendarDay(),
                )

                DateFieldPicker(
                    title: Localizations.expirationDate,
                    accessibilityIdentifier: "PassportExpirationDateEntry",
                    date: store.binding(
                        get: \.expirationDate,
                        send: AddEditPassportItemAction.expirationDateChanged,
                    ),
                )
            }
        }
    }
}

#if DEBUG
#Preview("Empty") {
    NavigationView {
        ScrollView {
            AddEditPassportItemView(
                store: Store(
                    processor: StateProcessor(
                        state: PassportItemState() as (any AddEditPassportItemState),
                    ),
                ),
            )
            .padding(16)
        }
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
        .navigationBar(title: "Empty Add Edit State", titleDisplayMode: .inline)
    }
}

#Preview("Populated") {
    NavigationView {
        ScrollView {
            AddEditPassportItemView(
                store: Store(
                    processor: StateProcessor(
                        state: PassportItemState.previewPopulated as (any AddEditPassportItemState),
                    ),
                ),
            )
            .padding(16)
        }
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
        .navigationBar(title: "Populated Add Edit State", titleDisplayMode: .inline)
    }
}

#Preview("Hidden Fields Visible") {
    NavigationView {
        ScrollView {
            AddEditPassportItemView(
                store: Store(
                    processor: StateProcessor(
                        state: {
                            var state = PassportItemState.previewPopulated
                            state.isPassportNumberVisible = true
                            state.isNationalIdentificationNumberVisible = true
                            return state
                        }() as (any AddEditPassportItemState),
                    ),
                ),
            )
            .padding(16)
        }
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
        .navigationBar(title: "Visible Add Edit State", titleDisplayMode: .inline)
    }
}

private extension PassportItemState {
    /// A fully populated state used by previews.
    static var previewPopulated: PassportItemState {
        PassportItemState(
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
    }
}
#endif
