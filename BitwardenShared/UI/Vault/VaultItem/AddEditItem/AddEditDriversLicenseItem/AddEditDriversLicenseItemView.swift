import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - AddEditDriversLicenseItemView

/// A view that allows the user to add or edit a driver's license item for a vault.
///
struct AddEditDriversLicenseItemView: View {
    // MARK: Properties

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
                )

                BitwardenTextField(
                    title: Localizations.middleName,
                    text: store.binding(
                        get: \.middleName,
                        send: AddEditDriversLicenseItemAction.middleNameChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseMiddleNameEntry",
                )

                BitwardenTextField(
                    title: Localizations.lastName,
                    text: store.binding(
                        get: \.lastName,
                        send: AddEditDriversLicenseItemAction.lastNameChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseLastNameEntry",
                )

                BitwardenTextField(
                    title: Localizations.licenseNumber,
                    text: store.binding(
                        get: \.licenseNumber,
                        send: AddEditDriversLicenseItemAction.licenseNumberChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseNumberEntry",
                    passwordVisibilityAccessibilityId: "ShowDriversLicenseNumberButton",
                    isPasswordVisible: store.binding(
                        get: \.isLicenseNumberVisible,
                        send: AddEditDriversLicenseItemAction.toggleLicenseNumberVisibilityChanged,
                    ),
                )

                // TODO: PM-38360 - replace with DateFieldPicker
                BitwardenTextField(
                    title: Localizations.dateOfBirth,
                    text: .constant(store.state.dateOfBirthDisplay),
                    accessibilityIdentifier: "DriversLicenseDateOfBirthEntry",
                    isTextFieldDisabled: true,
                )

                BitwardenTextField(
                    title: Localizations.issuingCountry,
                    text: store.binding(
                        get: \.issuingCountry,
                        send: AddEditDriversLicenseItemAction.issuingCountryChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseIssuingCountryEntry",
                )

                BitwardenTextField(
                    title: Localizations.issuingStateProvince,
                    text: store.binding(
                        get: \.issuingState,
                        send: AddEditDriversLicenseItemAction.issuingStateChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseIssuingStateEntry",
                )

                BitwardenTextField(
                    title: Localizations.issuingAuthority,
                    text: store.binding(
                        get: \.issuingAuthority,
                        send: AddEditDriversLicenseItemAction.issuingAuthorityChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseIssuingAuthorityEntry",
                )

                // TODO: PM-38360 - replace with DateFieldPicker
                BitwardenTextField(
                    title: Localizations.issueDate,
                    text: .constant(store.state.issueDateDisplay),
                    accessibilityIdentifier: "DriversLicenseIssueDateEntry",
                    isTextFieldDisabled: true,
                )

                // TODO: PM-38360 - replace with DateFieldPicker
                BitwardenTextField(
                    title: Localizations.expirationDate,
                    text: .constant(store.state.expirationDateDisplay),
                    accessibilityIdentifier: "DriversLicenseExpirationDateEntry",
                    isTextFieldDisabled: true,
                )

                BitwardenTextField(
                    title: Localizations.licenseClass,
                    text: store.binding(
                        get: \.licenseClass,
                        send: AddEditDriversLicenseItemAction.licenseClassChanged,
                    ),
                    accessibilityIdentifier: "DriversLicenseClassEntry",
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
    }
}
#endif
