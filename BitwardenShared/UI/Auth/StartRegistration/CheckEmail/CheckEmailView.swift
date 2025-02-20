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
                Image(decorative: Asset.Images.Illustrations.email)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(Asset.Colors.iconSecondary.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 36)
                    .padding(.bottom, 32)

                Text(Localizations.checkYourEmail)
                    .styleGuide(.title2, weight: .semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .padding([.bottom, .horizontal], 8)

                Text(LocalizedStringKey(store.state.headelineTextBoldEmail))
                    .styleGuide(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)
                    .tint(Asset.Colors.textPrimary.swiftUIColor)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                Text(Localizations.selectTheLinkInTheEmailToVerifyYourEmailAddressAndContinueCreatingYourAccount)
                    .styleGuide(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
                    .padding(.horizontal, 34)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                Button(Localizations.openEmailApp) {
                    openURL(URL(string: "message://")!)
                }
                .accessibilityIdentifier("OpenEmailAppButton")
                .padding(.bottom, 12)
                .buttonStyle(.primary())

                Button(Localizations.changeEmailAddress) {
                    store.send(.goBackTapped)
                }
                .accessibilityIdentifier("ChangeEmailAddressButton")
                .padding(.bottom, 32)
                .buttonStyle(.secondary())
            }
        }
        .navigationBar(title: Localizations.createAccount, titleDisplayMode: .inline)
        .scrollView(padding: 12)
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
