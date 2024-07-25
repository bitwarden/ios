import SwiftUI

// MARK: - CheckEmailView

/// A view that allows the user to create an account.
///
struct CheckEmailView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The store used to render the view.
    @ObservedObject var store: Store<CheckEmailState, CheckEmailAction, Void>

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .center, spacing: 0) {
                Image(decorative: Asset.Images.checkEmail)
                    .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)

                Text(Localizations.checkYourEmail)
                    .styleGuide(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .padding([.bottom, .horizontal], 8)

                Text(LocalizedStringKey(store.state.headelineTextBoldEmail))
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

                Text(LocalizedStringKey(Localizations.noEmailGoBackToEditYourEmailAddress))
                    .styleGuide(.subheadline)
                    .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .padding([.horizontal, .bottom], 32)
                    .environment(\.openURL, OpenURLAction { _ in
                        store.send(.goBackTapped)
                        return .handled
                    })

                Text(LocalizedStringKey(Localizations.orLogInYouMayAlreadyHaveAnAccount))
                    .styleGuide(.subheadline)
                    .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .padding(.horizontal, 32)
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
}

// MARK: Previews

#if DEBUG
#Preview {
    CheckEmailView(store: Store(processor: StateProcessor(state: CheckEmailState(email: "email@example.com"))))
}
#endif
