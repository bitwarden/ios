import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - ViewIdentityItemView

/// A view for displaying the contents of a identity item.
struct ViewIdentityItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<IdentityItemState, ViewItemAction, Void>

    var body: some View {
        personalDetailsSection
        identificationSection
        contactInfoSection
    }

    /// The section for displaying the identity's personal details.
    @ViewBuilder var personalDetailsSection: some View {
        if !store.state.isPersonalDetailsSectionEmpty {
            SectionView(Localizations.personalDetails, contentSpacing: 8) {
                ContentBlock {
                    if !store.state.identityName.isEmpty {
                        let identityName = store.state.identityName
                        BitwardenTextValueField(
                            title: Localizations.identityName,
                            value: identityName,
                            valueAccessibilityIdentifier: "ItemNameEntry",
                            copyButtonAccessibilityIdentifier: "IdentityCopyNameButton",
                            copyButtonAction: { store.send(.copyPressed(value: identityName, field: .identityName)) }
                        )
                        .accessibilityElement(children: .contain)
                    }

                    if !store.state.userName.isEmpty {
                        let username = store.state.userName
                        BitwardenTextValueField(
                            title: Localizations.username,
                            value: username,
                            valueAccessibilityIdentifier: "IdentityUsernameEntry",
                            copyButtonAccessibilityIdentifier: "IdentityCopyUsernameButton",
                            copyButtonAction: { store.send(.copyPressed(value: username, field: .username)) }
                        )
                        .accessibilityElement(children: .contain)
                    }

                    if !store.state.company.isEmpty {
                        let company = store.state.company
                        BitwardenTextValueField(
                            title: Localizations.company,
                            value: company,
                            valueAccessibilityIdentifier: "IdentityCompanyEntry",
                            copyButtonAccessibilityIdentifier: "IdentityCopyCompanyButton",
                            copyButtonAction: { store.send(.copyPressed(value: company, field: .company)) }
                        )
                        .accessibilityElement(children: .contain)
                    }
                }
            }
        }
    }

    /// The section for displaying the identity's identification details.
    @ViewBuilder var identificationSection: some View {
        if !store.state.isIdentificationSectionEmpty {
            SectionView(Localizations.identification, contentSpacing: 8) {
                ContentBlock {
                    if !store.state.socialSecurityNumber.isEmpty {
                        let socialSecurityNumber = store.state.socialSecurityNumber
                        BitwardenTextValueField(
                            title: Localizations.ssn,
                            value: socialSecurityNumber,
                            valueAccessibilityIdentifier: "IdentitySsnEntry",
                            copyButtonAccessibilityIdentifier: "IdentityCopySsnButton",
                            copyButtonAction: { store.send(
                                .copyPressed(
                                    value: socialSecurityNumber,
                                    field: .socialSecurityNumber
                                )
                            )
                            }
                        )
                        .accessibilityElement(children: .contain)
                    }

                    if !store.state.passportNumber.isEmpty {
                        let passportNumber = store.state.passportNumber
                        BitwardenTextValueField(
                            title: Localizations.passportNumber,
                            value: passportNumber,
                            valueAccessibilityIdentifier: "IdentityPassportNumberEntry",
                            copyButtonAccessibilityIdentifier: "IdentityCopyPassportNumberButton",
                            copyButtonAction: {
                                store.send(.copyPressed(value: passportNumber, field: .passportNumber))
                            }
                        )
                        .accessibilityElement(children: .contain)
                    }

                    if !store.state.licenseNumber.isEmpty {
                        let licenseNumber = store.state.licenseNumber
                        BitwardenTextValueField(
                            title: Localizations.licenseNumber,
                            value: licenseNumber,
                            valueAccessibilityIdentifier: "IdentityLicenseNumberEntry",
                            copyButtonAccessibilityIdentifier: "IdentityCopyLicenseNumberButton",
                            copyButtonAction: { store.send(
                                .copyPressed(
                                    value: licenseNumber,
                                    field: .licenseNumber
                                )
                            )
                            }
                        )
                        .accessibilityElement(children: .contain)
                    }
                }
            }
        }
    }

    /// The section for displaying the identity's contact info.
    @ViewBuilder var contactInfoSection: some View {
        if !store.state.isContactInfoSectionEmpty {
            SectionView(Localizations.contactInfo, contentSpacing: 8) {
                ContentBlock {
                    if !store.state.email.isEmpty {
                        let email = store.state.email
                        BitwardenTextValueField(
                            title: Localizations.email,
                            value: email,
                            valueAccessibilityIdentifier: "IdentityEmailEntry",
                            copyButtonAccessibilityIdentifier: "IdentityCopyEmailButton",
                            copyButtonAction: { store.send(.copyPressed(value: email, field: .email)) }
                        )
                        .accessibilityElement(children: .contain)
                    }

                    if !store.state.phone.isEmpty {
                        let phone = store.state.phone
                        BitwardenTextValueField(
                            title: Localizations.phone,
                            value: phone,
                            valueAccessibilityIdentifier: "IdentityPhoneEntry",
                            copyButtonAccessibilityIdentifier: "IdentityCopyPhoneButton",
                            copyButtonAction: { store.send(.copyPressed(value: phone, field: .phone)) }
                        )
                        .accessibilityElement(children: .contain)
                    }

                    if !store.state.fullAddress.isEmpty {
                        let fullAddress = store.state.fullAddress
                        BitwardenTextValueField(
                            title: Localizations.address,
                            value: fullAddress,
                            valueAccessibilityIdentifier: "IdentityAddressOneEntry",
                            copyButtonAccessibilityIdentifier: "IdentityCopyFullAddressButton",
                            copyButtonAction: { store.send(.copyPressed(value: fullAddress, field: .fullAddress)) }
                        )
                        .accessibilityElement(children: .contain)
                    }
                }
            }
        }
    }
}

#Preview("Empty Add Edit State") {
    NavigationView {
        ScrollView {
            LazyVStack(spacing: 20) {
                ViewIdentityItemView(
                    store: Store(
                        processor: StateProcessor(
                            state: IdentityItemState(
                                title: .custom(.dr),
                                firstName: "First",
                                lastName: "last",
                                middleName: "middle",
                                userName: "user name",
                                socialSecurityNumber: "12-34-1234",
                                address1: "address line 1",
                                address2: "address line 2",
                                address3: "address line 3",
                                cityOrTown: "City",
                                state: "State",
                                postalCode: "123",
                                country: "USA"
                            )
                        )
                    )
                )
            }
            .padding(16)
        }
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
        .ignoresSafeArea()
    }
}
