import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - AddEditBankAccountItemView

/// A view that allows the user to add or edit a bank account item for a vault.
///
struct AddEditBankAccountItemView: View {
    // MARK: Type

    /// The focusable fields in the bank account form.
    enum FocusedField: Int, Hashable {
        case bankName
        case nameOnAccount
        case accountType
        case accountNumber
        case routingNumber
        case branchNumber
        case pin
        case swiftCode
        case iban
        case bankPhone
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
        SectionView(Localizations.bankAccountDetails, contentSpacing: 8) {
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
                .textContentType(.name)
                .onSubmit { focusNextField($focusedField) }

                BitwardenMenuField(
                    title: Localizations.accountType,
                    accessibilityIdentifier: "BankAccountTypePicker",
                    options: DefaultableType<BankAccountType>.allCases,
                    selection: store.binding(
                        get: \.accountType,
                        send: AddEditBankAccountItemAction.accountTypeChanged,
                    ),
                )
                .focused($focusedField, equals: .accountType)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.accountNumber,
                    text: store.binding(
                        get: \.accountNumber,
                        send: AddEditBankAccountItemAction.accountNumberChanged,
                    ),
                    accessibilityIdentifier: "BankAccountNumberEntry",
                    passwordVisibilityAccessibilityId: "ShowBankAccountNumberButton",
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
                    accessibilityIdentifier: "BankRoutingNumberEntry",
                )
                .focused($focusedField, equals: .routingNumber)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.branchNumber,
                    text: store.binding(
                        get: \.branchNumber,
                        send: AddEditBankAccountItemAction.branchNumberChanged,
                    ),
                    accessibilityIdentifier: "BankBranchNumberEntry",
                )
                .focused($focusedField, equals: .branchNumber)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.pin,
                    text: store.binding(
                        get: \.pin,
                        send: AddEditBankAccountItemAction.pinChanged,
                    ),
                    accessibilityIdentifier: "BankPinEntry",
                    passwordVisibilityAccessibilityId: "ShowBankPinButton",
                    isPasswordVisible: store.binding(
                        get: \.isPinVisible,
                        send: AddEditBankAccountItemAction.togglePinVisibilityChanged,
                    ),
                )
                // Use the no-AutoFill-hint numeric configuration so iOS doesn't
                // offer SMS one-time-code suggestions on the bank account PIN field.
                .textFieldConfiguration(.numericNoContentType)
                .focused($focusedField, equals: .pin)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.swiftCode,
                    text: store.binding(
                        get: \.swiftCode,
                        send: AddEditBankAccountItemAction.swiftCodeChanged,
                    ),
                    accessibilityIdentifier: "BankSwiftCodeEntry",
                )
                .focused($focusedField, equals: .swiftCode)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.iban,
                    text: store.binding(
                        get: \.iban,
                        send: AddEditBankAccountItemAction.ibanChanged,
                    ),
                    accessibilityIdentifier: "BankIbanEntry",
                )
                .focused($focusedField, equals: .iban)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.bankContactPhone,
                    text: store.binding(
                        get: \.bankPhone,
                        send: AddEditBankAccountItemAction.bankPhoneChanged,
                    ),
                    accessibilityIdentifier: "BankPhoneEntry",
                )
                .textContentType(.telephoneNumber)
                .focused($focusedField, equals: .bankPhone)
                .onSubmit { focusNextField($focusedField) }
            }
        }
    }
}

#if DEBUG
struct AddEditBankAccountItemView_Previews: PreviewProvider {
    static var previews: some View {
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
        .previewDisplayName("Empty Add Edit State")

        NavigationView {
            ScrollView {
                AddEditBankAccountItemView(
                    store: Store(
                        processor: StateProcessor(
                            state: {
                                var state = BankAccountItemState()
                                state.bankName = "Bitwarden Bank"
                                state.nameOnAccount = "Bitwarden User"
                                state.accountType = .custom(.checking)
                                state.accountNumber = "1234567890"
                                state.routingNumber = "011000015"
                                state.branchNumber = "100"
                                state.pin = "1234"
                                state.swiftCode = "BTCBUS33"
                                state.iban = "GB82WEST12345698765432"
                                state.bankPhone = "555-123-4567"
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
        .previewDisplayName("Populated Add Edit State")
    }
}
#endif
