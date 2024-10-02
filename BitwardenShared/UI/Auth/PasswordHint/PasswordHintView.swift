import SwiftUI

// MARK: - PasswordHintView

/// A view that allows the user to request their master password hint.
///
struct PasswordHintView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<PasswordHintState, PasswordHintAction, PasswordHintEffect>

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BitwardenTextField(
                    title: Localizations.emailAddress,
                    text: store.binding(
                        get: \.emailAddress,
                        send: PasswordHintAction.emailAddressChanged
                    ),
                    footer: Localizations.enterEmailForHint
                )
                .textFieldConfiguration(.email)

                AsyncButton(Localizations.submit) {
                    await store.perform(.submitPressed)
                }
                .accessibilityIdentifier("SubmitButton")
                .buttonStyle(.primary())
                .disabled(!store.state.isSubmitButtonEnabled)
            }
            .padding(16)
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        .navigationTitle(Localizations.passwordHint)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismissPressed)
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
