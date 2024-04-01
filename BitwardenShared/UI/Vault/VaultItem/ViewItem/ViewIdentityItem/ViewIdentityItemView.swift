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
                titleAccessibilityIdentifier: "ItemName",
                value: store.state.identityName,
                valueAccessibilityIdentifier: "ItemValue"
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ItemRow")
        }

        if !store.state.userName.isEmpty {
            BitwardenTextValueField(
                title: Localizations.username,
                titleAccessibilityIdentifier: "ItemName",
                value: store.state.userName,
                valueAccessibilityIdentifier: "ItemValue"
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ItemRow")
        }

        if !store.state.company.isEmpty {
            BitwardenTextValueField(
                title: Localizations.company,
                titleAccessibilityIdentifier: "ItemName",
                value: store.state.company,
                valueAccessibilityIdentifier: "ItemValue"
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ItemRow")
        }

        if !store.state.socialSecurityNumber.isEmpty {
            BitwardenTextValueField(
                title: Localizations.ssn,
                titleAccessibilityIdentifier: "ItemName",
                value: store.state.socialSecurityNumber,
                valueAccessibilityIdentifier: "ItemValue"
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ItemRow")
        }

        if !store.state.passportNumber.isEmpty {
            BitwardenTextValueField(
                title: Localizations.passportNumber,
                titleAccessibilityIdentifier: "ItemName",
                value: store.state.passportNumber,
                valueAccessibilityIdentifier: "ItemValue"
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ItemRow")
        }

        if !store.state.licenseNumber.isEmpty {
            BitwardenTextValueField(
                title: Localizations.licenseNumber,
                titleAccessibilityIdentifier: "ItemName",
                value: store.state.licenseNumber,
                valueAccessibilityIdentifier: "ItemValue"
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ItemRow")
        }

        if !store.state.email.isEmpty {
            BitwardenTextValueField(
                title: Localizations.email,
                titleAccessibilityIdentifier: "ItemName",
                value: store.state.email,
                valueAccessibilityIdentifier: "ItemValue"
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ItemRow")
        }

        if !store.state.phone.isEmpty {
            BitwardenTextValueField(
                title: Localizations.phone,
                titleAccessibilityIdentifier: "ItemName",
                value: store.state.phone,
                valueAccessibilityIdentifier: "ItemValue"
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ItemRow")
        }

        if !store.state.fullAddress.isEmpty {
            BitwardenTextValueField(
                title: Localizations.address,
                titleAccessibilityIdentifier: "ItemName",
                value: store.state.fullAddress,
                valueAccessibilityIdentifier: "ItemValue"
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ItemRow")
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
