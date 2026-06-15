import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - ViewDriversLicenseItemView

/// A view for displaying the contents of a driver's license item.
struct ViewDriversLicenseItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<DriversLicenseItemState, ViewItemAction, Void>

    var body: some View {
        if !store.state.isLicenseDetailsSectionEmpty {
            SectionView(Localizations.licenseDetails, contentSpacing: 8) {
                ContentBlock {
                    firstNameItem

                    middleNameItem

                    lastNameItem

                    licenseNumberItem

                    dateField(title: Localizations.dateOfBirth, value: store.state.dateOfBirthDisplay)

                    issuingCountryItem

                    issuingStateItem

                    issuingAuthorityItem

                    dateField(title: Localizations.issueDate, value: store.state.issueDateDisplay)

                    dateField(title: Localizations.expirationDate, value: store.state.expirationDateDisplay)

                    licenseClassItem
                }
            }
        }
    }

    // MARK: Private Views

    /// The first name field.
    ///
    @ViewBuilder private var firstNameItem: some View {
        if !store.state.firstName.isEmpty {
            let firstName = store.state.firstName
            BitwardenTextValueField(
                title: Localizations.firstName,
                value: firstName,
                valueAccessibilityIdentifier: "DriversLicenseFirstNameEntry",
                copyButtonAccessibilityIdentifier: "DriversLicenseCopyFirstNameButton",
                copyButtonAction: { store.send(.copyPressed(value: firstName, field: .firstName)) },
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The middle name field.
    ///
    @ViewBuilder private var middleNameItem: some View {
        if !store.state.middleName.isEmpty {
            let middleName = store.state.middleName
            BitwardenTextValueField(
                title: Localizations.middleName,
                value: middleName,
                valueAccessibilityIdentifier: "DriversLicenseMiddleNameEntry",
                copyButtonAccessibilityIdentifier: "DriversLicenseCopyMiddleNameButton",
                copyButtonAction: { store.send(.copyPressed(value: middleName, field: .middleName)) },
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The last name field.
    ///
    @ViewBuilder private var lastNameItem: some View {
        if !store.state.lastName.isEmpty {
            let lastName = store.state.lastName
            BitwardenTextValueField(
                title: Localizations.lastName,
                value: lastName,
                valueAccessibilityIdentifier: "DriversLicenseLastNameEntry",
                copyButtonAccessibilityIdentifier: "DriversLicenseCopyLastNameButton",
                copyButtonAction: { store.send(.copyPressed(value: lastName, field: .lastName)) },
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The license number field, masked behind a visibility toggle with a copy button.
    ///
    @ViewBuilder private var licenseNumberItem: some View {
        let licenseNumber = store.state.licenseNumber
        let isVisible = store.state.isLicenseNumberVisible
        if !licenseNumber.isEmpty {
            BitwardenField(title: Localizations.licenseNumber) {
                PasswordText(password: licenseNumber, isPasswordVisible: isVisible)
                    .styleGuide(.body)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("DriversLicenseNumberEntry")
            } accessoryContent: {
                PasswordVisibilityButton(
                    accessibilityIdentifier: "ShowDriversLicenseNumberButton",
                    isPasswordVisible: isVisible,
                ) {
                    store.send(.driversLicenseItemAction(.toggleLicenseNumberVisibilityChanged))
                }

                Button {
                    store.send(.copyPressed(value: licenseNumber, field: .licenseNumber))
                } label: {
                    SharedAsset.Icons.copy24.swiftUIImage
                        .imageStyle(.accessoryIcon24)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("DriversLicenseCopyNumberButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    /// The issuing country field.
    ///
    @ViewBuilder private var issuingCountryItem: some View {
        if !store.state.issuingCountry.isEmpty {
            BitwardenTextValueField(
                title: Localizations.issuingCountry,
                value: store.state.issuingCountry,
                valueAccessibilityIdentifier: "DriversLicenseIssuingCountryEntry",
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The issuing state or province field.
    ///
    @ViewBuilder private var issuingStateItem: some View {
        if !store.state.issuingState.isEmpty {
            BitwardenTextValueField(
                title: Localizations.issuingStateProvince,
                value: store.state.issuingState,
                valueAccessibilityIdentifier: "DriversLicenseIssuingStateEntry",
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The issuing authority field.
    ///
    @ViewBuilder private var issuingAuthorityItem: some View {
        if !store.state.issuingAuthority.isEmpty {
            BitwardenTextValueField(
                title: Localizations.issuingAuthority,
                value: store.state.issuingAuthority,
                valueAccessibilityIdentifier: "DriversLicenseIssuingAuthorityEntry",
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The license class field.
    ///
    @ViewBuilder private var licenseClassItem: some View {
        if !store.state.licenseClass.isEmpty {
            BitwardenTextValueField(
                title: Localizations.licenseClass,
                value: store.state.licenseClass,
                valueAccessibilityIdentifier: "DriversLicenseClassEntry",
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// A read-only field displaying a long localized date, hidden when the value is empty.
    ///
    /// - Parameters:
    ///   - title: The localized title of the field.
    ///   - value: The formatted date string to display.
    ///
    @ViewBuilder
    private func dateField(title: String, value: String) -> some View {
        if !value.isEmpty {
            BitwardenTextValueField(title: title, value: value)
                .accessibilityElement(children: .contain)
        }
    }
}

// MARK: - DriversLicenseItemState

extension DriversLicenseItemState {
    /// Whether the license details section has no values to display.
    var isLicenseDetailsSectionEmpty: Bool {
        [
            firstName,
            middleName,
            lastName,
            licenseNumber,
            dateOfBirth,
            issuingCountry,
            issuingState,
            issuingAuthority,
            issueDate,
            expirationDate,
            licenseClass,
        ].allSatisfy(\.isEmpty)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Empty View State") {
    NavigationView {
        ScrollView {
            LazyVStack(spacing: 20) {
                ViewDriversLicenseItemView(
                    store: Store(
                        processor: StateProcessor(state: DriversLicenseItemState()),
                    ),
                )
            }
            .padding(16)
        }
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
        .ignoresSafeArea()
    }
}

#Preview("Populated View State") {
    NavigationView {
        ScrollView {
            LazyVStack(spacing: 20) {
                ViewDriversLicenseItemView(
                    store: Store(
                        processor: StateProcessor(
                            state: DriversLicenseItemState(
                                dateOfBirth: "2025-04-20",
                                expirationDate: "2026-08-10",
                                firstName: "Mitchell",
                                issueDate: "2021-08-10",
                                issuingAuthority: "DMV",
                                issuingCountry: "United States",
                                issuingState: "Wisconsin",
                                lastName: "Johnson",
                                licenseClass: "D",
                                licenseNumber: "1234567890",
                                middleName: "Allen",
                            ),
                        ),
                    ),
                )
            }
            .padding(16)
        }
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
        .ignoresSafeArea()
    }
}
#endif
