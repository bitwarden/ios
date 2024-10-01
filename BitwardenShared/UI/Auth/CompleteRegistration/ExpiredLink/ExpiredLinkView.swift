import SwiftUI

// MARK: - ExpiredLinkView

/// A view that allows the user to create an account.
///
struct ExpiredLinkView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<ExpiredLinkState, ExpiredLinkAction, Void>

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .center, spacing: 0) {
                Image(decorative: Asset.Images.expiredLink)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Asset.Colors.iconSecondary.swiftUIColor)
                    .padding([.bottom, .top], 32)

                Text(Localizations.expiredLink)
                    .styleGuide(.title2)
                    .padding(.bottom, 8)

                Text(Localizations.pleaseRestartRegistrationOrTryLoggingInYouMayAlreadyHaveAnAccount)
                    .styleGuide(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
                    .padding(.horizontal, 16)

                Button(Localizations.restartRegistration) {
                    store.send(.restartRegistrationTapped)
                }
                .accessibilityIdentifier("RestartRegistrationButton")
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .buttonStyle(.primary())

                Button(Localizations.logIn) {
                    store.send(.logInTapped)
                }
                .accessibilityIdentifier("LogInButton")
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .buttonStyle(.secondary())
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
    ExpiredLinkView(store: Store(processor: StateProcessor(state: ExpiredLinkState())))
}
#endif
