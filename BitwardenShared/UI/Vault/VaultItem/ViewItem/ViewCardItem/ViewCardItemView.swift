import SwiftUI

// MARK: - ViewCardItemView

struct ViewCardItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<any ViewCardItemState, ViewItemAction, ViewItemEffect>

    var body: some View {
        LazyVStack(spacing: 16.0) {
            cardholderNameItem

            cardNumberItem

            brandItem

            expirationItems

            securityCodeItem
        }
    }

    @ViewBuilder private var cardholderNameItem: some View {
        if !store.state.cardholderName.isEmpty {
            BitwardenTextValueField(
                title: Localizations.cardholderName,
                value: store.state.cardholderName
            )
        }
    }

    @ViewBuilder private var cardNumberItem: some View {
        let number = store.state.cardNumber
        let isVisible: Bool = store.state.isNumberVisible
        if !number.isEmpty {
            BitwardenField(title: Localizations.number) {
                PasswordText(password: number, isPasswordVisible: isVisible)
                    .styleGuide(.body)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
            } accessoryContent: {
                PasswordVisibilityButton(isPasswordVisible: isVisible) {
                    store.send(
                        .cardItemAction(
                            .toggleNumberVisibilityChanged(!isVisible)
                        )
                    )
                }

                Button {
                    store.send(.copyPressed(value: number))
                } label: {
                    Asset.Images.copy.swiftUIImage
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .accessibilityLabel(Localizations.copy)
            }
        }
    }

    @ViewBuilder private var brandItem: some View {
        if case .custom = store.state.brand {
            BitwardenTextValueField(
                title: Localizations.brand,
                value: store.state.brand.localizedName
            )
        }
    }

    @ViewBuilder private var expirationItems: some View {
        let expirationString: String = {
            var strings = [String]()
            if case let .custom(month) = store.state.expirationMonth {
                strings.append("\(month.rawValue)")
            }
            if !store.state.expirationYear.isEmpty {
                strings.append(store.state.expirationYear)
            }
            return strings
                .joined(separator: "/")
        }()
        if !expirationString.isEmpty {
            BitwardenTextValueField(
                title: Localizations.expiration,
                value: expirationString
            )
        }
    }

    @ViewBuilder private var securityCodeItem: some View {
        let code = store.state.cardSecurityCode
        let isVisible: Bool = store.state.isCodeVisible
        if !code.isEmpty {
            BitwardenField(title: Localizations.securityCode) {
                PasswordText(password: code, isPasswordVisible: isVisible)
                    .styleGuide(.body)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
            } accessoryContent: {
                PasswordVisibilityButton(isPasswordVisible: isVisible) {
                    store.send(
                        .cardItemAction(
                            .toggleCodeVisibilityChanged(!isVisible)
                        )
                    )
                }

                Button {
                    store.send(.copyPressed(value: code))
                } label: {
                    Asset.Images.copy.swiftUIImage
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .accessibilityLabel(Localizations.copy)
            }
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
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
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
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
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
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
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
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
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
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
            .navigationBar(title: "Hidden View State", titleDisplayMode: .inline)
        }
        .previewDisplayName("Year But Not Month")
    }
}
#endif
