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
                    footer: Localizations.enterEmailForHint,
                    text: store.binding(
                        get: \.emailAddress,
                        send: PasswordHintAction.emailAddressChanged
                    )
                )
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)

                AsyncButton(Localizations.submit) {
                    await store.perform(.submitPressed)
                }
                .buttonStyle(.primary())
                .disabled(!store.state.isSubmitButtonEnabled)
            }
            .padding(16)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .navigationTitle(Localizations.passwordHint)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                DismissButton {
                    store.send(.dismissPressed)
                }
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
