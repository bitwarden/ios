import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - AddEditDriversLicenseItemView

/// A view that allows the user to add or edit a driver's license item for a vault.
///
struct AddEditDriversLicenseItemView: View {
    // MARK: Types

    /// The focusable fields in the driver's license view.
    enum FocusedField: Int, Hashable {
        case firstName
        case middleName
        case lastName
        case licenseNumber
        case issuingCountry
        case issuingState
        case issuingAuthority
        case licenseClass
    }

    // MARK: Properties

    /// The currently focused field.
    @FocusState private var focusedField: FocusedField?

    /// The `Store` for this view.
    @ObservedObject var store: Store<
        any AddEditDriversLicenseItemState,
        AddEditDriversLicenseItemAction,
        AddEditItemEffect,
    >

    var body: some View {
        SectionView(Localizations.licenseDetails, contentSpacing: 8) {
            ContentBlock {
                BitwardenTextField(
                    title: Localizations.firstName,
                    text: store.binding(
                        get: \.firstName,
                        send: AddEditDriversLicenseItemAction.firstNameChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseFirstNameEntry",
                    focus: .field($focusedField, equals: .firstName),
                )
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.middleName,
                    text: store.binding(
                        get: \.middleName,
                        send: AddEditDriversLicenseItemAction.middleNameChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseMiddleNameEntry",
                    focus: .field($focusedField, equals: .middleName),
                )
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.lastName,
                    text: store.binding(
                        get: \.lastName,
                        send: AddEditDriversLicenseItemAction.lastNameChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseLastNameEntry",
                    focus: .field($focusedField, equals: .lastName),
                )
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.licenseNumber,
                    text: store.binding(
                        get: \.licenseNumber,
                        send: AddEditDriversLicenseItemAction.licenseNumberChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseNumberEntry",
                    passwordVisibilityAccessibilityId: "ShowDriversLicenseNumberButton",
                    passwordVisibilityFieldName: Localizations.licenseNumber,
                    focus: .field($focusedField, equals: .licenseNumber),
                    isPasswordVisible: store.binding(
                        get: \.isLicenseNumberVisible,
                        send: AddEditDriversLicenseItemAction.toggleLicenseNumberVisibilityChanged,
                    ),
                )
                .onSubmit { focusNextField($focusedField) }

                DateFieldPicker(
                    title: Localizations.dateOfBirth,
                    accessibilityIdentifier: "DriversLicenseDateOfBirthEntry",
                    date: store.binding(
                        get: \.dateOfBirth,
                        send: AddEditDriversLicenseItemAction.dateOfBirthChanged,
                    ),
                    in: Date.distantPast ... Date().asUTCCalendarDay(),
                )

                BitwardenTextField(
                    title: Localizations.issuingCountry,
                    text: store.binding(
                        get: \.issuingCountry,
                        send: AddEditDriversLicenseItemAction.issuingCountryChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseIssuingCountryEntry",
                    focus: .field($focusedField, equals: .issuingCountry),
                )
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.issuingStateProvince,
                    text: store.binding(
                        get: \.issuingState,
                        send: AddEditDriversLicenseItemAction.issuingStateChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseIssuingStateEntry",
                    focus: .field($focusedField, equals: .issuingState),
                )
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.issuingAuthority,
                    text: store.binding(
                        get: \.issuingAuthority,
                        send: AddEditDriversLicenseItemAction.issuingAuthorityChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseIssuingAuthorityEntry",
                    focus: .field($focusedField, equals: .issuingAuthority),
                )
                .onSubmit { focusNextField($focusedField) }

                DateFieldPicker(
                    title: Localizations.issueDate,
                    accessibilityIdentifier: "DriversLicenseIssueDateEntry",
                    date: store.binding(
                        get: \.issueDate,
                        send: AddEditDriversLicenseItemAction.issueDateChanged,
                    ),
                    in: Date.distantPast ... Date().asUTCCalendarDay(),
                )

                DateFieldPicker(
                    title: Localizations.expirationDate,
                    accessibilityIdentifier: "DriversLicenseExpirationDateEntry",
                    date: store.binding(
                        get: \.expirationDate,
                        send: AddEditDriversLicenseItemAction.expirationDateChanged,
                    ),
                )

                BitwardenTextField(
                    title: Localizations.licenseClass,
                    text: store.binding(
                        get: \.licenseClass,
                        send: AddEditDriversLicenseItemAction.licenseClassChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseClassEntry",
                    focus: .field($focusedField, equals: .licenseClass),
                )
            }
        }
    }
}

#if DEBUG
#Preview("Empty") {
    NavigationView {
        ScrollView {
            AddEditDriversLicenseItemView(
                store: Store(
                    processor: StateProcessor(
                        state: DriversLicenseItemState() as (any AddEditDriversLicenseItemState),
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
            AddEditDriversLicenseItemView(
                store: Store(
                    processor: StateProcessor(
                        state: DriversLicenseItemState.previewPopulated as (any AddEditDriversLicenseItemState),
                    ),
                ),
            )
            .padding(16)
        }
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
        .navigationBar(title: "Populated Add Edit State", titleDisplayMode: .inline)
    }
}

#Preview("License Number Visible") {
    NavigationView {
        ScrollView {
            AddEditDriversLicenseItemView(
                store: Store(
                    processor: StateProcessor(
                        state: {
                            var state = DriversLicenseItemState.previewPopulated
                            state.isLicenseNumberVisible = true
                            return state
                        }() as (any AddEditDriversLicenseItemState),
                    ),
                ),
            )
            .padding(16)
        }
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
        .navigationBar(title: "Visible Add Edit State", titleDisplayMode: .inline)
    }
}

private extension DriversLicenseItemState {
    /// A fully populated state used by previews.
    static var previewPopulated: DriversLicenseItemState {
        DriversLicenseItemState(
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
    }
}
#endif
