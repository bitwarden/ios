import BitwardenResources
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
        .scrollView()
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
        .navigationBar(title: Localizations.passwordHint, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismissPressed)
            }

            ToolbarItem(placement: .topBarTrailing) {
                primaryActionToolbarButton(Localizations.submit) {
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
