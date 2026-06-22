import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - ViewBankAccountItemView

/// A view for displaying the contents of a bank account item.
struct ViewBankAccountItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<BankAccountItemState, ViewItemAction, Void>

    var body: some View {
        if !store.state.isBankAccountDetailsSectionEmpty {
            SectionView(Localizations.accountDetails, contentSpacing: 8) {
                ContentBlock {
                    textField(
                        title: Localizations.bankName,
                        value: store.state.bankName,
                        valueAccessibilityIdentifier: "BankAccountBankNameEntry",
                    )

                    copyableTextField(
                        title: Localizations.nameOnAccount,
                        value: store.state.nameOnAccount,
                        valueAccessibilityIdentifier: "BankAccountNameOnAccountEntry",
                        copyButtonAccessibilityIdentifier: "BankAccountCopyNameOnAccountButton",
                        copyField: .nameOnAccount,
                    )

                    accountTypeItem

                    accountNumberItem

                    copyableTextField(
                        title: Localizations.routingNumber,
                        value: store.state.routingNumber,
                        valueAccessibilityIdentifier: "BankAccountRoutingNumberEntry",
                        copyButtonAccessibilityIdentifier: "BankAccountCopyRoutingNumberButton",
                        copyField: .routingNumber,
                    )

                    copyableTextField(
                        title: Localizations.branchNumber,
                        value: store.state.branchNumber,
                        valueAccessibilityIdentifier: "BankAccountBranchNumberEntry",
                        copyButtonAccessibilityIdentifier: "BankAccountCopyBranchNumberButton",
                        copyField: .branchNumber,
                    )

                    pinItem

                    copyableTextField(
                        title: Localizations.swiftCode,
                        value: store.state.swiftCode,
                        valueAccessibilityIdentifier: "BankAccountSwiftCodeEntry",
                        copyButtonAccessibilityIdentifier: "BankAccountCopySwiftCodeButton",
                        copyField: .swiftCode,
                    )

                    ibanItem

                    copyableTextField(
                        title: Localizations.bankContactPhone,
                        value: store.state.bankContactPhone,
                        valueAccessibilityIdentifier: "BankAccountContactPhoneEntry",
                        copyButtonAccessibilityIdentifier: "BankAccountCopyContactPhoneButton",
                        copyField: .bankContactPhone,
                    )
                }
            }
        }
    }

    // MARK: Private Views

    /// The account type field, displaying the selected type's localized name, hidden when no type is selected.
    @ViewBuilder private var accountTypeItem: some View {
        if let type = store.state.accountType.customValue {
            BitwardenTextValueField(
                title: Localizations.accountType,
                value: type.localizedName,
                valueAccessibilityIdentifier: "BankAccountTypeEntry",
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// The account number field, masked with a reveal toggle and a copy button, hidden when empty.
    @ViewBuilder private var accountNumberItem: some View {
        let accountNumber = store.state.accountNumber
        let isVisible = store.state.isAccountNumberVisible
        if !accountNumber.isEmpty {
            BitwardenField(title: Localizations.accountNumber) {
                PasswordText(password: accountNumber, isPasswordVisible: isVisible)
                    .styleGuide(.body)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("BankAccountNumberEntry")
            } accessoryContent: {
                PasswordVisibilityButton(
                    accessibilityIdentifier: "ShowBankAccountNumberButton",
                    isPasswordVisible: isVisible,
                ) {
                    store.send(.bankAccountItemAction(.toggleAccountNumberVisibilityChanged(!isVisible)))
                }

                Button {
                    store.send(.copyPressed(value: accountNumber, field: .accountNumber))
                } label: {
                    SharedAsset.Icons.copy24.swiftUIImage
                        .imageStyle(.accessoryIcon24)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("BankAccountCopyNumberButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    /// The IBAN field, masked with a reveal toggle and a copy button, hidden when empty.
    @ViewBuilder private var ibanItem: some View {
        let iban = store.state.iban
        let isVisible = store.state.isIbanVisible
        if !iban.isEmpty {
            BitwardenField(title: Localizations.iban) {
                PasswordText(password: iban, isPasswordVisible: isVisible)
                    .styleGuide(.body)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("BankAccountIbanEntry")
            } accessoryContent: {
                PasswordVisibilityButton(
                    accessibilityIdentifier: "ShowBankAccountIbanButton",
                    isPasswordVisible: isVisible,
                ) {
                    store.send(.bankAccountItemAction(.toggleIbanVisibilityChanged(!isVisible)))
                }

                Button {
                    store.send(.copyPressed(value: iban, field: .iban))
                } label: {
                    SharedAsset.Icons.copy24.swiftUIImage
                        .imageStyle(.accessoryIcon24)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("BankAccountCopyIbanButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    /// The PIN field, masked with a reveal toggle and a copy button, hidden when empty.
    @ViewBuilder private var pinItem: some View {
        let pin = store.state.pin
        let isVisible = store.state.isPinVisible
        if !pin.isEmpty {
            BitwardenField(title: Localizations.pin) {
                PasswordText(password: pin, isPasswordVisible: isVisible)
                    .styleGuide(.body)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("BankAccountPinEntry")
            } accessoryContent: {
                PasswordVisibilityButton(
                    accessibilityIdentifier: "ShowBankAccountPinButton",
                    isPasswordVisible: isVisible,
                ) {
                    store.send(.bankAccountItemAction(.togglePinVisibilityChanged(!isVisible)))
                }

                Button {
                    store.send(.copyPressed(value: pin, field: .pin))
                } label: {
                    SharedAsset.Icons.copy24.swiftUIImage
                        .imageStyle(.accessoryIcon24)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("BankAccountCopyPinButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    /// A read-only text field with a copy button, hidden when the value is empty.
    ///
    /// - Parameters:
    ///   - title: The localized title of the field.
    ///   - value: The value to display and copy.
    ///   - valueAccessibilityIdentifier: The accessibility identifier for the value.
    ///   - copyButtonAccessibilityIdentifier: The accessibility identifier for the copy button.
    ///   - copyField: The field identifying the value being copied.
    ///
    @ViewBuilder
    private func copyableTextField(
        title: String,
        value: String,
        valueAccessibilityIdentifier: String,
        copyButtonAccessibilityIdentifier: String,
        copyField: CopyableField,
    ) -> some View {
        if !value.isEmpty {
            BitwardenTextValueField(
                title: title,
                value: value,
                valueAccessibilityIdentifier: valueAccessibilityIdentifier,
                copyButtonAccessibilityIdentifier: copyButtonAccessibilityIdentifier,
                copyButtonAction: { store.send(.copyPressed(value: value, field: copyField)) },
            )
            .accessibilityElement(children: .contain)
        }
    }

    /// A read-only text field, hidden when the value is empty.
    ///
    /// - Parameters:
    ///   - title: The localized title of the field.
    ///   - value: The value to display.
    ///   - valueAccessibilityIdentifier: The accessibility identifier for the value.
    ///
    @ViewBuilder
    private func textField(
        title: String,
        value: String,
        valueAccessibilityIdentifier: String,
    ) -> some View {
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
                ViewBankAccountItemView(
                    store: Store(
                        processor: StateProcessor(state: BankAccountItemState()),
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
                ViewBankAccountItemView(
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
                                state.swiftCode = "BOFAUS3N"
                                state.iban = "GB33BUKB20201555555555"
                                state.bankContactPhone = "123-456-7890"
                                return state
                            }(),
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
