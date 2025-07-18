import BitwardenResources
import SwiftUI

// MARK: - AddEditCardItemView

/// A view that allows the user to add or edit a card item for a vault.
///
struct AddEditCardItemView: View {
    // MARK: Type

    /// The focusable fields in identity view.
    enum FocusedField: Int, Hashable {
        case cardholderName
        case number
        case brand
        case expirationMonth
        case expirationYear
        case securityCode
    }

    // MARK: Properties

    /// The currently focused field.
    @FocusState private var focusedField: FocusedField?

    /// The `Store` for this view.
    @ObservedObject var store: Store<any AddEditCardItemState, AddEditCardItemAction, AddEditItemEffect>

    var body: some View {
        SectionView(Localizations.cardDetails, contentSpacing: 8) {
            ContentBlock {
                BitwardenTextField(
                    title: Localizations.cardholderName,
                    text: store.binding(
                        get: \.cardholderName,
                        send: AddEditCardItemAction.cardholderNameChanged
                    ),
                    accessibilityIdentifier: "CardholderNameEntry"
                )
                .focused($focusedField, equals: .cardholderName)
                .textContentType(.creditCardNameOrName)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.number,
                    text: store.binding(
                        get: \.cardNumber,
                        send: AddEditCardItemAction.cardNumberChanged
                    ),
                    accessibilityIdentifier: "CardNumberEntry",
                    passwordVisibilityAccessibilityId: "ShowCardNumberButton",
                    isPasswordVisible: store.binding(
                        get: \.isNumberVisible,
                        send: AddEditCardItemAction.toggleNumberVisibilityChanged
                    )
                )
                .textFieldConfiguration(.numeric(.creditCardNumber))
                .focused($focusedField, equals: .number)
                .onSubmit { focusNextField($focusedField) }

                BitwardenMenuField(
                    title: Localizations.brand,
                    accessibilityIdentifier: "CardBrandPicker",
                    options: DefaultableType<CardComponent.Brand>.allCases,
                    selection: store.binding(
                        get: \.brand,
                        send: AddEditCardItemAction.brandChanged
                    )
                )
                .focused($focusedField, equals: .brand)
                .onSubmit { focusNextField($focusedField) }

                BitwardenMenuField(
                    title: Localizations.expirationMonth,
                    accessibilityIdentifier: "CardExpirationMonthPicker",
                    options: DefaultableType<CardComponent.Month>.allCases,
                    selection: store.binding(
                        get: \.expirationMonth,
                        send: AddEditCardItemAction.expirationMonthChanged
                    )
                )
                .focused($focusedField, equals: .expirationMonth)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.expirationYear,
                    text: store.binding(
                        get: \.expirationYear,
                        send: AddEditCardItemAction.expirationYearChanged
                    ),
                    accessibilityIdentifier: "CardExpirationYearEntry"
                )
                .textFieldConfiguration(
                    .numeric(.creditCardExpirationYearOrDateTime)
                )
                .focused($focusedField, equals: .expirationYear)
                .onSubmit { focusNextField($focusedField) }

                BitwardenTextField(
                    title: Localizations.securityCode,
                    text: store.binding(
                        get: \.cardSecurityCode,
                        send: AddEditCardItemAction.cardSecurityCodeChanged
                    ),
                    accessibilityIdentifier: "CardSecurityCodeEntry",
                    passwordVisibilityAccessibilityId: "CardShowSecurityCodeButton",
                    isPasswordVisible: store.binding(
                        get: \.isCodeVisible,
                        send: AddEditCardItemAction.toggleCodeVisibilityChanged
                    )
                )
                .textFieldConfiguration(.numeric(.creditCardSecurityCodeOrPassword))
                .focused($focusedField, equals: .securityCode)
                .onSubmit { focusNextField($focusedField) }
            }
        }
    }
}

#if DEBUG
struct AddEditCardItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                AddEditCardItemView(
                    store: Store(
                        processor: StateProcessor(
                            state: CardItemState() as (any AddEditCardItemState)
                        )
                    )
                )
                .padding(16)
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .navigationBar(title: "Empty Add Edit State", titleDisplayMode: .inline)
        }
        .previewDisplayName("Empty Add Edit State")

        NavigationView {
            ScrollView {
                AddEditCardItemView(
                    store: Store(
                        processor: StateProcessor(
                            state: {
                                var state = CardItemState()
                                state.brand = .custom(.visa)
                                state.cardNumber = "4400123456789"
                                state.cardSecurityCode = "123"
                                state.cardholderName = "Bitwarden User"
                                state.expirationMonth = .custom(.aug)
                                state.expirationYear = "1989"
                                return state
                            }() as (any AddEditCardItemState)
                        )
                    )
                )
                .padding(16)
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .navigationBar(title: "Hidden Add Edit State", titleDisplayMode: .inline)
        }
        .previewDisplayName("Hidden Add Edit State")

        NavigationView {
            ScrollView {
                AddEditCardItemView(
                    store: Store(
                        processor: StateProcessor(
                            state: {
                                var state = CardItemState()
                                state.brand = .custom(.visa)
                                state.cardNumber = "4400123456789"
                                state.cardSecurityCode = "123"
                                state.cardholderName = "Bitwarden User"
                                state.expirationMonth = .custom(.aug)
                                state.expirationYear = "1989"
                                state.isCodeVisible = true
                                state.isNumberVisible = true
                                return state
                            }() as (any AddEditCardItemState)
                        )
                    )
                )
                .padding(16)
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .navigationBar(title: "Visible Add Edit State", titleDisplayMode: .inline)
        }
        .previewDisplayName("Visible Add Edit State")
    }
}
#endif
