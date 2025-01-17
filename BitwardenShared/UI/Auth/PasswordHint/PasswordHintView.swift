import SwiftUI

// MARK: - PasswordHintView

/// A view that allows the user to request their master password hint.
///
struct PasswordHintView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<PasswordHintState, PasswordHintAction, PasswordHintEffect>

    var body: some View {
        VStack(spacing: 24) {
            BitwardenTextField(
                title: Localizations.emailAddress,
                text: store.binding(
                    get: \.emailAddress,
                    send: PasswordHintAction.emailAddressChanged
                ),
                footer: Localizations.enterEmailForHint
            )
            .textFieldConfiguration(.email)
        }
        .scrollView(padding: 12)
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        .navigationTitle(Localizations.passwordHint)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismissPressed)
            }

            ToolbarItem(placement: .topBarTrailing) {
                toolbarButton(Localizations.submit) {
                    await store.perform(.submitPressed)
                }
                .accessibilityIdentifier("SubmitButton")
                .disabled(!store.state.isSubmitButtonEnabled)
            }
        }
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    NavigationView {
        PasswordHintView(
            store: Store(
                processor: StateProcessor(
                    state: PasswordHintState(
                        emailAddress: "email@example.com"
                    )
                )
            )
        )
    }
}
#endif
