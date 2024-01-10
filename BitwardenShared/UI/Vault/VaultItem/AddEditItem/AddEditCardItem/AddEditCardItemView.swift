import SwiftUI

// MARK: - AddEditCardItemView

/// A view that allows the user to add or edit a card item for a vault.
///
struct AddEditCardItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<any AddEditCardItemState, AddEditCardItemAction, AddEditItemEffect>

    var body: some View {
        LazyVStack(spacing: 16.0) {
            BitwardenTextField(
                title: Localizations.cardholderName,
                text: store.binding(
                    get: \.cardholderName,
                    send: AddEditCardItemAction.cardholderNameChanged
                )
            )

            BitwardenTextField(
                title: Localizations.number,
                text: store.binding(
                    get: \.cardNumber,
                    send: AddEditCardItemAction.cardNumberChanged
                ), isTextFieldTextVisible: store.binding(
                    get: \.isNumberVisible,
                    send: AddEditCardItemAction.toggleNumberVisibilityChanged
                )
            )
            .textFieldConfiguration(.password)

            BitwardenMenuField(
                title: Localizations.brand,
                options: DefaultableType<CardComponent.Brand>.allCases,
                selection: store.binding(
                    get: \.brand,
                    send: AddEditCardItemAction.brandChanged
                )
            )

            BitwardenMenuField(
                title: Localizations.expirationMonth,
                options: DefaultableType<CardComponent.Month>.allCases,
                selection: store.binding(
                    get: \.expirationMonth,
                    send: AddEditCardItemAction.expirationMonthChanged
                )
            )

            BitwardenTextField(
                title: Localizations.expirationYear,
                text: store.binding(
                    get: \.expirationYear,
                    send: AddEditCardItemAction.expirationYearChanged
                )
            )

            BitwardenTextField(
                title: Localizations.securityCode,
                text: store.binding(
                    get: \.cardSecurityCode,
                    send: AddEditCardItemAction.cardSecurityCodeChanged
                ), isTextFieldTextVisible: store.binding(
                    get: \.isCodeVisible,
                    send: AddEditCardItemAction.toggleCodeVisibilityChanged
                )
            )
            .textFieldConfiguration(.password)
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
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
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
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
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
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
            .navigationBar(title: "Visible Add Edit State", titleDisplayMode: .inline)
        }
        .previewDisplayName("Visible Add Edit State")
    }
}
#endif
