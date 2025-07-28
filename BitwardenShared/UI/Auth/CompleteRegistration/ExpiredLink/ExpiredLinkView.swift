import BitwardenResources
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
        VStack(spacing: 24) {
            VStack(alignment: .center, spacing: 12) {
                Text(Localizations.expiredLink)
                    .styleGuide(.title2, weight: .semibold)

                Text(Localizations.pleaseRestartRegistrationOrTryLoggingInYouMayAlreadyHaveAnAccount)
                    .styleGuide(.headline)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button(Localizations.restartRegistration) {
                    store.send(.restartRegistrationTapped)
                }
                .accessibilityIdentifier("RestartRegistrationButton")
                .buttonStyle(.primary())

                Button(Localizations.logIn) {
                    store.send(.logInTapped)
                }
                .accessibilityIdentifier("LogInButton")
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
