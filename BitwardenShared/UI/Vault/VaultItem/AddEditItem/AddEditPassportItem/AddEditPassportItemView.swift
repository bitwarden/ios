import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - AddEditPassportItemView

/// A view that allows the user to add or edit a passport item for a vault.
///
struct AddEditPassportItemView: View {
    // MARK: Properties

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
                )

                BitwardenTextField(
                    title: Localizations.lastName,
                    text: store.binding(
                        get: \.surname,
                        send: AddEditPassportItemAction.surnameChanged,
                    ),
                    accessibilityIdentifier: "PassportLastNameEntry",
                )

                // TODO: PM-38360 - replace with DateFieldPicker
                BitwardenTextField(
                    title: Localizations.dateOfBirth,
                    text: .constant(store.state.dateOfBirthDisplay),
                    accessibilityIdentifier: "PassportDateOfBirthEntry",
                    isTextFieldDisabled: true,
                )

                BitwardenTextField(
                    title: Localizations.sex,
                    text: store.binding(
                        get: \.sex,
                        send: AddEditPassportItemAction.sexChanged,
                    ),
                    accessibilityIdentifier: "PassportSexEntry",
                )

                BitwardenTextField(
                    title: Localizations.birthPlace,
                    text: store.binding(
                        get: \.birthPlace,
                        send: AddEditPassportItemAction.birthPlaceChanged,
                    ),
                    accessibilityIdentifier: "PassportBirthPlaceEntry",
                )

                BitwardenTextField(
                    title: Localizations.nationality,
                    text: store.binding(
                        get: \.nationality,
                        send: AddEditPassportItemAction.nationalityChanged,
                    ),
                    accessibilityIdentifier: "PassportNationalityEntry",
                )

                BitwardenTextField(
                    title: Localizations.passportNumber,
                    text: store.binding(
                        get: \.passportNumber,
                        send: AddEditPassportItemAction.passportNumberChanged,
                    ),
                    accessibilityIdentifier: "PassportNumberEntry",
                    passwordVisibilityAccessibilityId: "ShowPassportNumberButton",
                    isPasswordVisible: store.binding(
                        get: \.isPassportNumberVisible,
                        send: AddEditPassportItemAction.togglePassportNumberVisibilityChanged,
                    ),
                )

                BitwardenTextField(
                    title: Localizations.passportType,
                    text: store.binding(
                        get: \.passportType,
                        send: AddEditPassportItemAction.passportTypeChanged,
                    ),
                    accessibilityIdentifier: "PassportTypeEntry",
                )

                BitwardenTextField(
                    title: Localizations.nationalIdentificationNumber,
                    text: store.binding(
                        get: \.nationalIdentificationNumber,
                        send: AddEditPassportItemAction.nationalIdentificationNumberChanged,
                    ),
                    accessibilityIdentifier: "PassportNationalIdentificationNumberEntry",
                    passwordVisibilityAccessibilityId: "ShowPassportNationalIdentificationNumberButton",
                    isPasswordVisible: store.binding(
                        get: \.isNationalIdentificationNumberVisible,
                        send: AddEditPassportItemAction.toggleNationalIdentificationNumberVisibilityChanged,
                    ),
                )

                BitwardenTextField(
                    title: Localizations.issuingCountry,
                    text: store.binding(
                        get: \.issuingCountry,
                        send: AddEditPassportItemAction.issuingCountryChanged,
                    ),
                    accessibilityIdentifier: "PassportIssuingCountryEntry",
                )

                BitwardenTextField(
                    title: Localizations.issuingAuthorityOffice,
                    text: store.binding(
                        get: \.issuingAuthority,
                        send: AddEditPassportItemAction.issuingAuthorityChanged,
                    ),
                    accessibilityIdentifier: "PassportIssuingAuthorityEntry",
                )

                // TODO: PM-38360 - replace with DateFieldPicker
                BitwardenTextField(
                    title: Localizations.issueDate,
                    text: .constant(store.state.issueDateDisplay),
                    accessibilityIdentifier: "PassportIssueDateEntry",
                    isTextFieldDisabled: true,
                )

                // TODO: PM-38360 - replace with DateFieldPicker
                BitwardenTextField(
                    title: Localizations.expirationDate,
                    text: .constant(store.state.expirationDateDisplay),
                    accessibilityIdentifier: "PassportExpirationDateEntry",
                    isTextFieldDisabled: true,
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
    }
}
#endif
