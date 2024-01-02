import SwiftUI

// MARK: - SingleSignOnView

/// A view that allows users to login using their single-sign on identifier.
///
struct SingleSignOnView: View {
    // MARK: Properties

    @ObservedObject var store: Store<SingleSignOnState, SingleSignOnAction, SingleSignOnEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            instructionsText

            identifierTextField

            loginButton
        }
        .scrollView()
        .navigationBar(title: Localizations.bitwarden, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
    }

    // MARK: Private Views

    /// The identifier text field.
    private var identifierTextField: some View {
        BitwardenTextField(
            title: Localizations.orgIdentifier,
            text: store.binding(
                get: \.identifierText,
                send: SingleSignOnAction.identifierTextChanged
            )
        )
    }

    /// The instructions text.
    private var instructionsText: some View {
        Text(Localizations.logInSsoSummary)
            .styleGuide(.body)
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
    }

    /// The login button.
    private var loginButton: some View {
        AsyncButton(Localizations.logIn) {
            await store.perform(.loginTapped)
        }
        .buttonStyle(.primary())
    }
}

// MARK: Previews

#Preview {
    SingleSignOnView(store: Store(processor: StateProcessor(state: SingleSignOnState())))
}
