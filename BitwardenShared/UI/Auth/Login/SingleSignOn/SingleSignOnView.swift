import BitwardenResources
import SwiftUI

// MARK: - SingleSignOnView

/// A view that allows users to login using their single-sign on identifier.
///
struct SingleSignOnView: View {
    // MARK: Properties

    @ObservedObject var store: Store<SingleSignOnState, SingleSignOnAction, SingleSignOnEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 24) {
            instructionsText

            identifierTextField
        }
        .padding(.top, 12)
        .scrollView()
        .navigationBar(title: Localizations.bitwarden, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }

            ToolbarItem(placement: .topBarTrailing) {
                toolbarButton(Localizations.logIn) {
                    await store.perform(.loginTapped)
                }
                .accessibilityIdentifier("SSOLoginButton")
            }
        }
        .task {
            await store.perform(.loadSingleSignOnDetails)
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
            ),
            accessibilityIdentifier: "SSOOrgIdField"
        )
    }

    /// The instructions text.
    private var instructionsText: some View {
        Text(Localizations.logInSsoSummary)
            .styleGuide(.body)
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
    }
}

// MARK: Previews

#Preview {
    SingleSignOnView(store: Store(processor: StateProcessor(
        state: SingleSignOnState()
    ))).navStackWrapped
}
