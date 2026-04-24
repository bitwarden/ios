import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - ViewBankAccountItemView

/// A view for displaying the contents of a bank account item in read-only mode, with copy
/// buttons and visibility toggles for hidden fields.
///
struct ViewBankAccountItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<
        any ViewBankAccountItemState,
        ViewItemAction,
        ViewItemEffect,
    >

    var body: some View {
        if !store.state.isBankAccountDetailsSectionEmpty {
            SectionView(Localizations.bankAccountDetails, contentSpacing: 8) {
                ContentBlock {
                    bankNameItem

                    nameOnAccountItem

                    accountTypeItem

                    accountNumberItem

                    routingNumberItem

                    branchNumberItem

                    pinItem

                    swiftCodeItem

                    ibanItem

                    bankPhoneItem
                }
            }
        }
    }

    // MARK: Private Views

    @ViewBuilder private var bankNameItem: some View {
        let value = store.state.bankName
        if !value.isEmpty {
            BitwardenTextValueField(
                title: Localizations.bankName,
                value: value,
                valueAccessibilityIdentifier: "BankNameEntry",
            ) {
                copyButton(value: value, field: .bankName, identifier: "BankCopyNameButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder private var nameOnAccountItem: some View {
        let value = store.state.nameOnAccount
        if !value.isEmpty {
            BitwardenTextValueField(
                title: Localizations.nameOnAccount,
                value: value,
                valueAccessibilityIdentifier: "NameOnAccountEntry",
            ) {
                copyButton(value: value, field: .bankNameOnAccount, identifier: "BankCopyNameOnAccountButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder private var accountTypeItem: some View {
        if case .custom = store.state.accountType {
            BitwardenTextValueField(
                title: Localizations.accountType,
                value: store.state.accountType.localizedName,
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ItemRow")
        }
    }

    @ViewBuilder private var accountNumberItem: some View {
        let value = store.state.accountNumber
        let isVisible = store.state.isAccountNumberVisible
        if !value.isEmpty {
            BitwardenField(title: Localizations.accountNumber) {
                PasswordText(password: value, isPasswordVisible: isVisible)
                    .styleGuide(.body)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("BankAccountNumberEntry")
            } accessoryContent: {
                PasswordVisibilityButton(
                    accessibilityIdentifier: "ShowBankAccountNumberButton",
                    isPasswordVisible: isVisible,
                ) {
                    store.send(
                        .bankAccountItemAction(
                            .toggleAccountNumberVisibilityChanged(!isVisible),
                        ),
                    )
                }

                copyButton(value: value, field: .bankAccountNumber, identifier: "BankCopyAccountNumberButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder private var routingNumberItem: some View {
        let value = store.state.routingNumber
        if !value.isEmpty {
            BitwardenTextValueField(
                title: Localizations.routingNumber,
                value: value,
                valueAccessibilityIdentifier: "BankRoutingNumberEntry",
            ) {
                copyButton(value: value, field: .bankRoutingNumber, identifier: "BankCopyRoutingNumberButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder private var branchNumberItem: some View {
        let value = store.state.branchNumber
        if !value.isEmpty {
            BitwardenTextValueField(
                title: Localizations.branchNumber,
                value: value,
                valueAccessibilityIdentifier: "BankBranchNumberEntry",
            ) {
                copyButton(value: value, field: .bankBranchNumber, identifier: "BankCopyBranchNumberButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder private var pinItem: some View {
        let value = store.state.pin
        let isVisible = store.state.isPinVisible
        if !value.isEmpty {
            BitwardenField(title: Localizations.pin) {
                PasswordText(password: value, isPasswordVisible: isVisible)
                    .styleGuide(.body)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("BankPinEntry")
            } accessoryContent: {
                PasswordVisibilityButton(
                    accessibilityIdentifier: "ShowBankPinButton",
                    isPasswordVisible: isVisible,
                ) {
                    store.send(
                        .bankAccountItemAction(
                            .togglePinVisibilityChanged(!isVisible),
                        ),
                    )
                }

                copyButton(value: value, field: .bankPin, identifier: "BankCopyPinButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder private var swiftCodeItem: some View {
        let value = store.state.swiftCode
        if !value.isEmpty {
            BitwardenTextValueField(
                title: Localizations.swiftCode,
                value: value,
                valueAccessibilityIdentifier: "BankSwiftCodeEntry",
            ) {
                copyButton(value: value, field: .bankSwiftCode, identifier: "BankCopySwiftCodeButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder private var ibanItem: some View {
        let value = store.state.iban
        if !value.isEmpty {
            BitwardenTextValueField(
                title: Localizations.iban,
                value: value,
                valueAccessibilityIdentifier: "BankIbanEntry",
            ) {
                copyButton(value: value, field: .bankIban, identifier: "BankCopyIbanButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder private var bankPhoneItem: some View {
        let value = store.state.bankPhone
        if !value.isEmpty {
            BitwardenTextValueField(
                title: Localizations.bankContactPhone,
                value: value,
                valueAccessibilityIdentifier: "BankPhoneEntry",
            ) {
                copyButton(value: value, field: .bankPhone, identifier: "BankCopyPhoneButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    /// Helper to render a copy button.
    @ViewBuilder
    private func copyButton(value: String, field: CopyableField, identifier: String) -> some View {
        Button {
            store.send(.copyPressed(value: value, field: field))
        } label: {
            SharedAsset.Icons.copy24.swiftUIImage
                .imageStyle(.accessoryIcon24)
        }
        .accessibilityLabel(Localizations.copy)
        .accessibilityIdentifier(identifier)
    }
}

#if DEBUG
struct ViewBankAccountItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                ViewBankAccountItemView(
                    store: Store(
                        processor: StateProcessor(
                            state: {
                                var state = BankAccountItemState()
                                state.bankName = "Bitwarden Bank"
                                state.nameOnAccount = "Bitwarden User"
                                state.accountType = .custom(.checking)
                                state.accountNumber = "1234567890"
                                state.routingNumber = "011000015"
                                state.pin = "1234"
                                state.iban = "GB82WEST12345698765432"
                                return state
                            }() as (any ViewBankAccountItemState),
                        ),
                    ),
                )
                .padding(16)
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .navigationBar(title: "Bank Account", titleDisplayMode: .inline)
        }
        .previewDisplayName("Populated View State")
    }
}
#endif
