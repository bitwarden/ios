import SwiftUI

// MARK: - RemoveMasterPasswordView

/// A view that notifies the user that they need to remove their master password.
///
struct RemoveMasterPasswordView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<RemoveMasterPasswordState, RemoveMasterPasswordAction, Void>

    // MARK: View

    var body: some View {
        VStack(spacing: 24) {
            Text(Localizations.removeMasterPasswordMessage(store.state.organizationName))

            Button(Localizations.continue) {
                store.send(.continueFlow)
            }
            .buttonStyle(.primary())
        }
        .navigationBar(title: Localizations.removeMasterPassword, titleDisplayMode: .inline)
        .scrollView()
    }
}

// MARK: - Previews

#if DEBUG
#Preview("RemoveMasterPassword") {
    RemoveMasterPasswordView(
        store: Store(
            processor: StateProcessor(
                state: RemoveMasterPasswordState(
                    organizationName: "Example Org"
                )
            )
        )
    )
}
#endif
