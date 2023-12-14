import SwiftUI

// MARK: - AddEditIdentityItemView

/// A view that allows the user to add or edit Identity part of the cipherItem to a vault.
///
struct AddEditIdentityItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<IdentityItemState, AddEditIdentityItemAction, AddEditItemEffect>

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            BitwardenMenuField(
                title: Localizations.title,
                options: [.default(TitleType.defaultStateTitle)] + TitleType.allCases.map(DefaultableType.custom),
                selection: store.binding(
                    get: \.title,
                    send: AddEditIdentityItemAction.titleChanged
                )
            )

            BitwardenTextField(
                title: Localizations.firstName,
                text: store.binding(
                    get: \.firsName,
                    send: AddEditIdentityItemAction.firstNameChanged
                )
            )

            BitwardenTextField(
                title: Localizations.middleName,
                text: store.binding(
                    get: \.middleName,
                    send: AddEditIdentityItemAction.middleNameChanged
                )
            )

            BitwardenTextField(
                title: Localizations.lastName,
                text: store.binding(
                    get: \.lastName,
                    send: AddEditIdentityItemAction.firstNameChanged
                )
            )

            BitwardenTextField(
                title: Localizations.username,
                text: store.binding(
                    get: \.userName,
                    send: AddEditIdentityItemAction.userNameChanged
                )
            )

            BitwardenTextField(
                title: Localizations.company,
                text: store.binding(
                    get: \.company,
                    send: AddEditIdentityItemAction.companyChanged
                )
            )

            BitwardenTextField(
                title: Localizations.ssn,
                text: store.binding(
                    get: \.socialSecurityNumber,
                    send: AddEditIdentityItemAction.socialSecurityNumberChanged
                )
            )

            BitwardenTextField(
                title: Localizations.passportNumber,
                text: store.binding(
                    get: \.passportNumber,
                    send: AddEditIdentityItemAction.passportNumberChanged
                )
            )

            BitwardenTextField(
                title: Localizations.licenseNumber,
                text: store.binding(
                    get: \.licenseNumber,
                    send: AddEditIdentityItemAction.licenseNumberChanged
                )
            )

            BitwardenTextField(
                title: Localizations.email,
                text: store.binding(
                    get: \.email,
                    send: AddEditIdentityItemAction.emailChanged
                )
            )

            BitwardenTextField(
                title: Localizations.phone,
                text: store.binding(
                    get: \.phone,
                    send: AddEditIdentityItemAction.phoneNumberChanged
                )
            )

            BitwardenTextField(
                title: Localizations.address1,
                text: store.binding(
                    get: \.address1,
                    send: AddEditIdentityItemAction.address1Changed
                )
            )

            BitwardenTextField(
                title: Localizations.address2,
                text: store.binding(
                    get: \.address2,
                    send: AddEditIdentityItemAction.address2Changed
                )
            )

            BitwardenTextField(
                title: Localizations.address3,
                text: store.binding(
                    get: \.address3,
                    send: AddEditIdentityItemAction.address3Changed
                )
            )

            BitwardenTextField(
                title: Localizations.cityTown,
                text: store.binding(
                    get: \.cityOrTown,
                    send: AddEditIdentityItemAction.cityOrTownChanged
                )
            )

            BitwardenTextField(
                title: Localizations.stateProvince,
                text: store.binding(
                    get: \.stateOrPostalCode,
                    send: AddEditIdentityItemAction.stateOrPostalCodeChanged
                )
            )

            BitwardenTextField(
                title: Localizations.country,
                text: store.binding(
                    get: \.country,
                    send: AddEditIdentityItemAction.countryChanged
                )
            )
        }
    }
}

// MARK: Previews

#if DEBUG
struct AddEditIdentityItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    AddEditIdentityItemView(
                        store: Store(
                            processor: StateProcessor(
                                state: IdentityItemState()
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
}
#endif
