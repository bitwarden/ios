import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - AddEditBankAccountItemView

/// A view that allows the user to add or edit a bank account item for a vault.
///
struct AddEditBankAccountItemView: View {
    // MARK: Type

    /// The focusable fields in the bank account view.
    enum FocusedField: Int, Hashable {
        case bankName
        case nameOnAccount
        case accountNumber
        case routingNumber
        case branchNumber
        case pin
        case swiftCode
        case iban
        case bankContactPhone
    }

    // MARK: Properties

    /// The currently focused field.
    @FocusState private var focusedField: FocusedField?

    /// The `Store` for this view.
    @ObservedObject var store: Store<
        any AddEditBankAccountItemState,
        AddEditBankAccountItemAction,
        AddEditItemEffect,
    >

    var body: some View {
        SectionView(Localizations.accountDetails, contentSpacing: 8) {
            ContentBlock {
                BitwardenTextField(
                    title: Localizations.bankName,
                    text: store.binding(
                        get: \.bankName,
                        send: AddEditBankAccountItemAction.bankNameChanged,
                    ),
                    accessibilityIdentifier: "BankNameEntry",
                )
                .focused($focusedField, equals: .bankName)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.nameOnAccount,
                    text: store.binding(
                        get: \.nameOnAccount,
                        send: AddEditBankAccountItemAction.nameOnAccountChanged,
                    ),
                    accessibilityIdentifier: "NameOnAccountEntry",
                )
                .focused($focusedField, equals: .nameOnAccount)
                .onSubmit { focusNextField($focusedField) }

                BitwardenMenuField(
                    title: Localizations.accountType,
                    accessibilityIdentifier: "AccountTypePicker",
                    options: DefaultableType<BankAccountType>.allCases,
                    selection: store.binding(
                        get: \.accountType,
                        send: AddEditBankAccountItemAction.accountTypeChanged,
                    ),
                )

                BitwardenTextField(
                    title: Localizations.accountNumber,
                    text: store.binding(
                        get: \.accountNumber,
                        send: AddEditBankAccountItemAction.accountNumberChanged,
                    ),
                    accessibilityIdentifier: "AccountNumberEntry",
                    passwordVisibilityAccessibilityId: "ShowAccountNumberButton",
                    isPasswordVisible: store.binding(
                        get: \.isAccountNumberVisible,
                        send: AddEditBankAccountItemAction.toggleAccountNumberVisibilityChanged,
                    ),
                )
                .focused($focusedField, equals: .accountNumber)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.routingNumber,
                    text: store.binding(
                        get: \.routingNumber,
                        send: AddEditBankAccountItemAction.routingNumberChanged,
                    ),
                    accessibilityIdentifier: "RoutingNumberEntry",
                )
                .focused($focusedField, equals: .routingNumber)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.branchNumber,
                    text: store.binding(
                        get: \.branchNumber,
                        send: AddEditBankAccountItemAction.branchNumberChanged,
                    ),
                    accessibilityIdentifier: "BranchNumberEntry",
                )
                .focused($focusedField, equals: .branchNumber)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.pin,
                    text: store.binding(
                        get: \.pin,
                        send: AddEditBankAccountItemAction.pinChanged,
                    ),
                    accessibilityIdentifier: "PinEntry",
                    passwordVisibilityAccessibilityId: "ShowPinButton",
                    isPasswordVisible: store.binding(
                        get: \.isPinVisible,
                        send: AddEditBankAccountItemAction.togglePinVisibilityChanged,
                    ),
                )
                .focused($focusedField, equals: .pin)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.swiftCode,
                    text: store.binding(
                        get: \.swiftCode,
                        send: AddEditBankAccountItemAction.swiftCodeChanged,
                    ),
                    accessibilityIdentifier: "SwiftCodeEntry",
                )
                .focused($focusedField, equals: .swiftCode)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.iban,
                    text: store.binding(
                        get: \.iban,
                        send: AddEditBankAccountItemAction.ibanChanged,
                    ),
                    accessibilityIdentifier: "IbanEntry",
                    passwordVisibilityAccessibilityId: "ShowIbanButton",
                    isPasswordVisible: store.binding(
                        get: \.isIbanVisible,
                        send: AddEditBankAccountItemAction.toggleIbanVisibilityChanged,
                    ),
                )
                .focused($focusedField, equals: .iban)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.bankContactPhone,
                    text: store.binding(
                        get: \.bankContactPhone,
                        send: AddEditBankAccountItemAction.bankContactPhoneChanged,
                    ),
                    accessibilityIdentifier: "BankContactPhoneEntry",
                )
                .textFieldConfiguration(.numeric(.telephoneNumber))
                .focused($focusedField, equals: .bankContactPhone)
            }
        }
    }
}

#if DEBUG
#Preview("Empty") {
    NavigationView {
        ScrollView {
            AddEditBankAccountItemView(
                store: Store(
                    processor: StateProcessor(
                        state: BankAccountItemState() as (any AddEditBankAccountItemState),
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
            AddEditBankAccountItemView(
                store: Store(
                    processor: StateProcessor(
                        state: {
                            var state = BankAccountItemState()
                            state.bankName = "Bank of America"
                            state.nameOnAccount = "Personal Checking"
                            state.accountType = .custom(.checking)
                            state.accountNumber = "1234567890123456"
                            state.routingNumber = "1234567890"
                            state.branchNumber = "100"
                            state.pin = "1234"
                            state.swiftCode = "123234"
                            state.iban = "23423434543"
                            state.bankContactPhone = "123-456-7890"
                            return state
                        }() as (any AddEditBankAccountItemState),
                    ),
                ),
            )
            .padding(16)
        }
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
        .navigationBar(title: "Populated Add Edit State", titleDisplayMode: .inline)
    }
}
#endif
