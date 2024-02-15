import SwiftUI

// MARK: - AddEditIdentityItemView

/// A view that allows the user to add or edit Identity part of the cipherItem to a vault.
///
struct AddEditIdentityItemView: View {
    // MARK: Type

    /// The focusable fields in identity view.
    enum FocusedField: Int, Hashable {
        case firstName
        case middleName
        case lastName
        case username
        case company
        case ssn
        case passport
        case license
        case email
        case phone
        case address1
        case address2
        case address3
        case city
        case state
        case zipcode
        case country
    }

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<IdentityItemState, AddEditIdentityItemAction, AddEditItemEffect>

    /// The currently focused field.
    @FocusState private var focusedField: FocusedField?

    // MARK: Views

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            BitwardenMenuField(
                title: Localizations.title,
                options: DefaultableType<TitleType>.allCases,
                selection: store.binding(
                    get: \.title,
                    send: AddEditIdentityItemAction.titleChanged
                )
            )

            BitwardenTextField(
                title: Localizations.firstName,
                text: store.binding(
                    get: \.firstName,
                    send: AddEditIdentityItemAction.firstNameChanged
                )
            )
            .focused($focusedField, equals: .firstName)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.middleName,
                text: store.binding(
                    get: \.middleName,
                    send: AddEditIdentityItemAction.middleNameChanged
                )
            )
            .focused($focusedField, equals: .middleName)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.lastName,
                text: store.binding(
                    get: \.lastName,
                    send: AddEditIdentityItemAction.lastNameChanged
                )
            )
            .focused($focusedField, equals: .lastName)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.username,
                text: store.binding(
                    get: \.userName,
                    send: AddEditIdentityItemAction.userNameChanged
                )
            )
            .textFieldConfiguration(.username)
            .focused($focusedField, equals: .username)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.company,
                text: store.binding(
                    get: \.company,
                    send: AddEditIdentityItemAction.companyChanged
                )
            )
            .focused($focusedField, equals: .company)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.ssn,
                text: store.binding(
                    get: \.socialSecurityNumber,
                    send: AddEditIdentityItemAction.socialSecurityNumberChanged
                )
            )
            .focused($focusedField, equals: .ssn)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.passportNumber,
                text: store.binding(
                    get: \.passportNumber,
                    send: AddEditIdentityItemAction.passportNumberChanged
                )
            )
            .focused($focusedField, equals: .passport)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.licenseNumber,
                text: store.binding(
                    get: \.licenseNumber,
                    send: AddEditIdentityItemAction.licenseNumberChanged
                )
            )
            .focused($focusedField, equals: .license)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.email,
                text: store.binding(
                    get: \.email,
                    send: AddEditIdentityItemAction.emailChanged
                )
            )
            .textFieldConfiguration(.email)
            .focused($focusedField, equals: .email)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.phone,
                text: store.binding(
                    get: \.phone,
                    send: AddEditIdentityItemAction.phoneNumberChanged
                )
            )
            .textFieldConfiguration(.phone)
            .focused($focusedField, equals: .phone)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.address1,
                text: store.binding(
                    get: \.address1,
                    send: AddEditIdentityItemAction.address1Changed
                )
            )
            .focused($focusedField, equals: .address1)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.address2,
                text: store.binding(
                    get: \.address2,
                    send: AddEditIdentityItemAction.address2Changed
                )
            )
            .focused($focusedField, equals: .address2)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.address3,
                text: store.binding(
                    get: \.address3,
                    send: AddEditIdentityItemAction.address3Changed
                )
            )
            .focused($focusedField, equals: .address3)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.cityTown,
                text: store.binding(
                    get: \.cityOrTown,
                    send: AddEditIdentityItemAction.cityOrTownChanged
                )
            )
            .focused($focusedField, equals: .city)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.stateProvince,
                text: store.binding(
                    get: \.state,
                    send: AddEditIdentityItemAction.stateChanged
                )
            )
            .focused($focusedField, equals: .state)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.zipPostalCode,
                text: store.binding(
                    get: \.postalCode,
                    send: AddEditIdentityItemAction.postalCodeChanged
                )
            )
            .focused($focusedField, equals: .zipcode)
            .onSubmit { focusNextField($focusedField) }

            BitwardenTextField(
                title: Localizations.country,
                text: store.binding(
                    get: \.country,
                    send: AddEditIdentityItemAction.countryChanged
                )
            )
            .focused($focusedField, equals: .country)
            .onSubmit { focusNextField($focusedField) }
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
        .previewDisplayName("Empty Add Edit Identity State")
    }
}
#endif
