import SwiftUI

// MARK: - CheckEmailView

/// A view that allows the user to create an account.
///
struct CheckEmailView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The store used to render the view.
    @ObservedObject var store: Store<CheckEmailState, CheckEmailAction, CheckEmailEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .center, spacing: 0) {
                Image(decorative: Asset.Images.checkEmail)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)

                Text(Localizations.checkYourEmail)
                    .styleGuide(.title2)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)

                Text(.init(store.state.headelineTextBoldEmail))
                    .styleGuide(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
                    .padding(.horizontal, 34)
                    .tint(Asset.Colors.textPrimary.swiftUIColor)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                Button(Localizations.openEmailApp) {
                    openURL(URL(string: "message://")!)
                }
                .accessibilityIdentifier("OpenEmailAppButton")
                .padding(.horizontal, 50)
                .padding(.bottom, 32)
                .buttonStyle(.primary())

                Text(.init(store.state.goBackText))
                    .styleGuide(.subheadline)
                    .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
                    .padding([.horizontal, .bottom], 32)
                    .accessibilityAction(named: Localizations.goBack) {
                        store.send(.goBackTapped)
                    }
                    .environment(\.openURL, OpenURLAction { _ in
                        store.send(.goBackTapped)
                        return .handled
                    })

                Text(.init(store.state.logInText))
                    .styleGuide(.subheadline)
                    .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
                    .padding(.horizontal, 32)
                    .accessibilityAction(named: Localizations.logIn) {
                        store.send(.logInTapped)
                    }
                    .environment(\.openURL, OpenURLAction { _ in
                        store.send(.logInTapped)
                        return .handled
                    })
            }
        }
        .navigationBar(title: Localizations.createAccount, titleDisplayMode: .inline)
        .scrollView()
        .toolbar {
            cancelToolbarItem {
                store.send(.dismissTapped)
            }
        }
    }

    // MARK: Private views

    func attributedText(withString string: String, boldString: String, font: UIFont) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: string,
                                                         attributes: [NSAttributedString.Key.font: font])
        let boldFontAttribute: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: font.pointSize)]
        let range = (string as NSString).range(of: boldString)
        attributedString.addAttributes(boldFontAttribute, range: range)
        return attributedString
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    CheckEmailView(store: Store(processor: StateProcessor(state: CheckEmailState())))
}
#endif
