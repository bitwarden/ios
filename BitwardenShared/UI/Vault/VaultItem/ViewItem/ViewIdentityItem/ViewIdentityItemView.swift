import BitwardenSdk
import SwiftUI

// MARK: - ViewIdentityItemView

/// A view for displaying the contents of a identity item.
struct ViewIdentityItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<IdentityItemState, ViewItemAction, Void>

    var body: some View {
        if !store.state.identityName.isEmpty {
            BitwardenTextValueField(
                title: Localizations.identityName,
                value: store.state.identityName,
                valueAccessibilityIdentifier: "ItemNameEntry"
            )
            .accessibilityElement(children: .contain)
        }

        if !store.state.userName.isEmpty {
            BitwardenTextValueField(
                title: Localizations.username,
                value: store.state.userName,
                valueAccessibilityIdentifier: "IdentityUsernameEntry"
            )
            .accessibilityElement(children: .contain)
        }

        if !store.state.company.isEmpty {
            BitwardenTextValueField(
                title: Localizations.company,
                value: store.state.company,
                valueAccessibilityIdentifier: "IdentityCompanyEntry"
            )
            .accessibilityElement(children: .contain)
        }

        if !store.state.socialSecurityNumber.isEmpty {
            BitwardenTextValueField(
                title: Localizations.ssn,
                value: store.state.socialSecurityNumber,
                valueAccessibilityIdentifier: "IdentitySsnEntry"
            )
            .accessibilityElement(children: .contain)
        }

        if !store.state.passportNumber.isEmpty {
            BitwardenTextValueField(
                title: Localizations.passportNumber,
                value: store.state.passportNumber,
                valueAccessibilityIdentifier: "IdentityPassportNumberEntry"
            )
            .accessibilityElement(children: .contain)
        }

        if !store.state.licenseNumber.isEmpty {
            BitwardenTextValueField(
                title: Localizations.licenseNumber,
                value: store.state.licenseNumber,
                valueAccessibilityIdentifier: "IdentityLicenseNumberEntry"
            )
            .accessibilityElement(children: .contain)
        }

        if !store.state.email.isEmpty {
            BitwardenTextValueField(
                title: Localizations.email,
                value: store.state.email,
                valueAccessibilityIdentifier: "IdentityEmailEntry"
            )
            .accessibilityElement(children: .contain)
        }

        if !store.state.phone.isEmpty {
            BitwardenTextValueField(
                title: Localizations.phone,
                value: store.state.phone,
                valueAccessibilityIdentifier: "IdentityPhoneEntry"
            )
            .accessibilityElement(children: .contain)
        }

        if !store.state.fullAddress.isEmpty {
            BitwardenTextValueField(
                title: Localizations.address,
                value: store.state.fullAddress,
                valueAccessibilityIdentifier: "IdentityAddressOneEntry"
            )
            .accessibilityElement(children: .contain)
        }
    }
}

#Preview {
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
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .ignoresSafeArea()
    }
    .previewDisplayName("Empty Add Edit State")
}
