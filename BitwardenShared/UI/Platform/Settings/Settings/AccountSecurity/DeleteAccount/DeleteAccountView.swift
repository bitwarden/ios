import SwiftUI

// MARK: - DeleteAccountView

/// A view that lets the user delete their account.
///
struct DeleteAccountView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<DeleteAccountState, DeleteAccountAction, DeleteAccountEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image(asset: Asset.Images.exclamationTriangle)
                .scaledFrame(width: 24, height: 24)
                .foregroundColor(Color(asset: Asset.Colors.loadingRed))

            Text(Localizations.deletingYourAccountIsPermanent)
                .foregroundColor(Color(asset: Asset.Colors.loadingRed))
                .styleGuide(.headline, weight: .semibold)

            Text(Localizations.deleteAccountExplanation)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .styleGuide(.subheadline)

            VStack(spacing: 12) {
                AsyncButton(Localizations.deleteAccount) {
                    await store.perform(.deleteAccount)
                }
                .buttonStyle(.primary(isDestructive: true))
                .accessibilityIdentifier("DELETE ACCOUNT")

                Button {
                    store.send(.dismiss)
                } label: {
                    Text(Localizations.cancel)
                }
                .buttonStyle(.tertiary(isDestructive: true))
                .accessibilityIdentifier("CANCEL")
            }
        }
        .navigationBar(title: Localizations.deleteAccount, titleDisplayMode: .inline)
        .scrollView()
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
    }
}

// MARK: Previews

#Preview {
    DeleteAccountView(store: Store(processor: StateProcessor(state: DeleteAccountState())))
}
