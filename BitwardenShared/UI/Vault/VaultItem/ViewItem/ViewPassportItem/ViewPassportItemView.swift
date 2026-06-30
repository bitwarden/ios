import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - ViewPassportItemView

/// A view for displaying the contents of a passport item.
struct ViewPassportItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<PassportItemState, ViewItemAction, Void>

    var body: some View {
        if !store.state.isPassportDetailsSectionEmpty {
            SectionView(Localizations.passportDetails, contentSpacing: 8) {
                ContentBlock {
                    givenNameItem

                    surnameItem

                    dateField(
                        title: Localizations.dateOfBirth,
                        value: store.state.dateOfBirthDisplay,
                        valueAccessibilityIdentifier: "PassportDateOfBirthEntry",
                    )

                    sexItem

                    birthPlaceItem

                    nationalityItem

                    passportNumberItem

                    passportTypeItem

                    nationalIdentificationNumberItem

                    issuingCountryItem

                    issuingAuthorityItem

                    dateField(
                        title: Localizations.issueDate,
                        value: store.state.issueDateDisplay,
                        valueAccessibilityIdentifier: "PassportIssueDateEntry",
                    )

                    dateField(
                        title: Localizations.expirationDate,
                        value: store.state.expirationDateDisplay,
                        valueAccessibilityIdentifier: "PassportExpirationDateEntry",
                    )
                }
            }
        }
    }

    // MARK: Private Views

    /// The given name field.
    ///
    @ViewBuilder private var givenNameItem: some View {
        if !store.state.givenName.isEmpty {
            let givenName = store.state.givenName
            BitwardenTextValueField(
                title: Localizations.firstName,
                value: givenName,
                valueAccessibilityIdentifier: "PassportFirstNameEntry",
                copyButtonAccessibilityIdentifier: "PassportCopyFirstNameButton",
                copyButtonAction: { store.send(.copyPressed(value: givenName, field: .givenName)) },
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The surname field.
    ///
    @ViewBuilder private var surnameItem: some View {
        if !store.state.surname.isEmpty {
            let surname = store.state.surname
            BitwardenTextValueField(
                title: Localizations.lastName,
                value: surname,
                valueAccessibilityIdentifier: "PassportLastNameEntry",
                copyButtonAccessibilityIdentifier: "PassportCopyLastNameButton",
                copyButtonAction: { store.send(.copyPressed(value: surname, field: .surname)) },
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The sex field.
    ///
    @ViewBuilder private var sexItem: some View {
        if !store.state.sex.isEmpty {
            BitwardenTextValueField(
                title: Localizations.sex,
                value: store.state.sex,
                valueAccessibilityIdentifier: "PassportSexEntry",
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The birth place field.
    ///
    @ViewBuilder private var birthPlaceItem: some View {
        if !store.state.birthPlace.isEmpty {
            BitwardenTextValueField(
                title: Localizations.birthPlace,
                value: store.state.birthPlace,
                valueAccessibilityIdentifier: "PassportBirthPlaceEntry",
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The nationality field.
    ///
    @ViewBuilder private var nationalityItem: some View {
        if !store.state.nationality.isEmpty {
            BitwardenTextValueField(
                title: Localizations.nationality,
                value: store.state.nationality,
                valueAccessibilityIdentifier: "PassportNationalityEntry",
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The passport number field, masked behind a reveal toggle with a copy control.
    ///
    @ViewBuilder private var passportNumberItem: some View {
        let passportNumber = store.state.passportNumber
        let isVisible = store.state.isPassportNumberVisible
        if !passportNumber.isEmpty {
            BitwardenField(title: Localizations.passportNumber) {
                PasswordText(password: passportNumber, isPasswordVisible: isVisible)
                    .styleGuide(.body)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("PassportNumberEntry")
            } accessoryContent: {
                PasswordVisibilityButton(
                    accessibilityIdentifier: "ShowPassportNumberButton",
                    isPasswordVisible: isVisible,
                ) {
                    store.send(.passportItemAction(.togglePassportNumberVisibilityChanged(!isVisible)))
                }

                Button {
                    store.send(.copyPressed(value: passportNumber, field: .passportNumber))
                } label: {
                    SharedAsset.Icons.copy24.swiftUIImage
                        .imageStyle(.accessoryIcon24)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("PassportCopyNumberButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    /// The passport type field.
    ///
    @ViewBuilder private var passportTypeItem: some View {
        if !store.state.passportType.isEmpty {
            BitwardenTextValueField(
                title: Localizations.passportType,
                value: store.state.passportType,
                valueAccessibilityIdentifier: "PassportTypeEntry",
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The national identification number field, masked behind a reveal toggle with a copy control.
    ///
    @ViewBuilder private var nationalIdentificationNumberItem: some View {
        let nationalIdentificationNumber = store.state.nationalIdentificationNumber
        let isVisible = store.state.isNationalIdentificationNumberVisible
        if !nationalIdentificationNumber.isEmpty {
            BitwardenField(title: Localizations.nationalIdentificationNumber) {
                PasswordText(password: nationalIdentificationNumber, isPasswordVisible: isVisible)
                    .styleGuide(.body)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("PassportNationalIdentificationNumberEntry")
            } accessoryContent: {
                PasswordVisibilityButton(
                    accessibilityIdentifier: "ShowPassportNationalIdentificationNumberButton",
                    isPasswordVisible: isVisible,
                ) {
                    store.send(
                        .passportItemAction(.toggleNationalIdentificationNumberVisibilityChanged(!isVisible)),
                    )
                }

                Button {
                    store.send(.copyPressed(value: nationalIdentificationNumber, field: .nationalIdentificationNumber))
                } label: {
                    SharedAsset.Icons.copy24.swiftUIImage
                        .imageStyle(.accessoryIcon24)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("PassportCopyNationalIdentificationNumberButton")
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
                valueAccessibilityIdentifier: "PassportIssuingCountryEntry",
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The issuing authority field.
    ///
    @ViewBuilder private var issuingAuthorityItem: some View {
        if !store.state.issuingAuthority.isEmpty {
            BitwardenTextValueField(
                title: Localizations.issuingAuthorityOffice,
                value: store.state.issuingAuthority,
                valueAccessibilityIdentifier: "PassportIssuingAuthorityEntry",
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// A read-only field displaying a long localized date, hidden when the value is empty.
    ///
    /// - Parameters:
    ///   - title: The localized title of the field.
    ///   - value: The formatted date string to display.
    ///   - valueAccessibilityIdentifier: The accessibility identifier for the value.
    ///
    @ViewBuilder
    private func dateField(title: String, value: String, valueAccessibilityIdentifier: String) -> some View {
        if !value.isEmpty {
            BitwardenTextValueField(
                title: title,
                value: value,
                valueAccessibilityIdentifier: valueAccessibilityIdentifier,
            )
            .accessibilityElement(children: .contain)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Empty View State") {
    NavigationView {
        ScrollView {
            LazyVStack(spacing: 20) {
                ViewPassportItemView(
                    store: Store(
                        processor: StateProcessor(state: PassportItemState()),
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
                ViewPassportItemView(
                    store: Store(
                        processor: StateProcessor(
                            state: PassportItemState(
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
