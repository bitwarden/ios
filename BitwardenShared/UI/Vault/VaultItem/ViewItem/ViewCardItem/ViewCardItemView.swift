import BitwardenResources
import SwiftUI

// MARK: - ViewCardItemView

struct ViewCardItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<any ViewCardItemState, ViewItemAction, ViewItemEffect>

    var body: some View {
        if !store.state.isCardDetailsSectionEmpty {
            SectionView(Localizations.cardDetails, contentSpacing: 8) {
                ContentBlock {
                    cardholderNameItem

                    cardNumberItem

                    brandItem

                    expirationItems

                    securityCodeItem
                }
            }
        }
    }

    @ViewBuilder private var cardholderNameItem: some View {
        if !store.state.cardholderName.isEmpty {
            BitwardenTextValueField(
                title: Localizations.cardholderName,
                value: store.state.cardholderName,
                valueAccessibilityIdentifier: "CardholderNameEntry"
            )
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder private var cardNumberItem: some View {
        let number = store.state.cardNumber
        let isVisible: Bool = store.state.isNumberVisible
        if !number.isEmpty {
            BitwardenField(title: Localizations.number) {
                PasswordText(password: number, isPasswordVisible: isVisible)
                    .styleGuide(.body)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("CardNumberEntry")
            } accessoryContent: {
                PasswordVisibilityButton(
                    accessibilityIdentifier: "ShowCardNumberButton",
                    isPasswordVisible: isVisible
                ) {
                    store.send(
                        .cardItemAction(
                            .toggleNumberVisibilityChanged(!isVisible)
                        )
                    )
                }

                Button {
                    store.send(.copyPressed(value: number, field: .cardNumber))
                } label: {
                    Asset.Images.copy24.swiftUIImage
                        .imageStyle(.accessoryIcon24)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("CardCopyNumberButton")
            }
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder private var brandItem: some View {
        if case .custom = store.state.brand {
            BitwardenTextValueField(
                title: Localizations.brand,
                value: store.state.brandName
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ItemRow")
        }
    }

    @ViewBuilder private var expirationItems: some View {
        let expirationString = store.state.expirationString
        if !expirationString.isEmpty {
            BitwardenTextValueField(
                title: Localizations.expiration,
                value: expirationString,
                valueAccessibilityIdentifier: "CardExpirationYearEntry"
            )
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder private var securityCodeItem: some View {
        let code = store.state.cardSecurityCode
        let isVisible: Bool = store.state.isCodeVisible
        if !code.isEmpty {
            BitwardenField(title: Localizations.securityCode) {
                PasswordText(password: code, isPasswordVisible: isVisible)
                    .styleGuide(.body)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("CardSecurityCodeEntry")
            } accessoryContent: {
                PasswordVisibilityButton(
                    accessibilityIdentifier: "CardShowSecurityCodeButton",
                    isPasswordVisible: isVisible
                ) {
                    store.send(
                        .cardItemAction(
                            .toggleCodeVisibilityChanged(!isVisible)
                        )
                    )
                }

                Button {
                    store.send(.copyPressed(value: code, field: .securityCode))
                } label: {
                    Asset.Images.copy24.swiftUIImage
                        .imageStyle(.accessoryIcon24)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("CardCopySecurityNumberButton")
            }
            .accessibilityElement(children: .contain)
        }
    }
}

#if DEBUG
struct ViewCardItemView_Previews: PreviewProvider {
    static var previews: some View {
        emptyPreview

        fullPreview

        hiddenCodePreview

        noExpiration

        yearOnlyExpiration
    }

    @ViewBuilder static var emptyPreview: some View {
        NavigationView {
            ScrollView {
                ViewCardItemView(
                    store: Store(
                        processor: StateProcessor(
                            state: CardItemState() as (any ViewCardItemState)
                        )
                    )
                )
                .padding(16)
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .navigationBar(title: "Empty View State", titleDisplayMode: .inline)
        }
        .previewDisplayName("Empty View State")
    }

    @ViewBuilder static var fullPreview: some View {
        NavigationView {
            ScrollView {
                ViewCardItemView(
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
                            }() as (any ViewCardItemState)
                        )
                    )
                )
                .padding(16)
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .navigationBar(title: "Visible View State", titleDisplayMode: .inline)
        }
        .previewDisplayName("Visible Add Edit State")
    }

    @ViewBuilder static var hiddenCodePreview: some View {
        NavigationView {
            ScrollView {
                ViewCardItemView(
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
                            }() as (any ViewCardItemState)
                        )
                    )
                )
                .padding(16)
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .navigationBar(title: "Hidden View State", titleDisplayMode: .inline)
        }
        .previewDisplayName("Hidden View State")
    }

    @ViewBuilder static var noExpiration: some View {
        NavigationView {
            ScrollView {
                ViewCardItemView(
                    store: Store(
                        processor: StateProcessor(
                            state: {
                                var state = CardItemState()
                                state.brand = .custom(.visa)
                                state.cardNumber = "4400123456789"
                                state.cardSecurityCode = "123"
                                state.cardholderName = "Bitwarden User"
                                state.expirationMonth = .default
                                state.expirationYear = ""
                                return state
                            }() as (any ViewCardItemState)
                        )
                    )
                )
                .padding(16)
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .navigationBar(title: "Hidden View State", titleDisplayMode: .inline)
        }
        .previewDisplayName("No Expiration")
    }

    @ViewBuilder static var yearOnlyExpiration: some View {
        NavigationView {
            ScrollView {
                ViewCardItemView(
                    store: Store(
                        processor: StateProcessor(
                            state: {
                                var state = CardItemState()
                                state.brand = .custom(.visa)
                                state.cardNumber = "4400123456789"
                                state.cardSecurityCode = "123"
                                state.cardholderName = "Bitwarden User"
                                state.expirationMonth = .default
                                state.expirationYear = "1989"
                                return state
                            }() as (any ViewCardItemState)
                        )
                    )
                )
                .padding(16)
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .navigationBar(title: "Hidden View State", titleDisplayMode: .inline)
        }
        .previewDisplayName("Year But Not Month")
    }
}
#endif
