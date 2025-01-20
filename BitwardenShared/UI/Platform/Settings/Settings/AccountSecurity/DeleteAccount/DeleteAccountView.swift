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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(asset: Asset.Images.warning24)
                    .foregroundColor(Color(asset: Asset.Colors.error))

                VStack(alignment: .leading, spacing: 2) {
                    Text(Localizations.deletingYourAccountIsPermanent)
                        .foregroundColor(Color(asset: Asset.Colors.error))
                        .styleGuide(
                            .headline,
                            weight: .semibold,
                            includeLinePadding: false,
                            includeLineSpacing: false
                        )

                    Text(Localizations.deleteAccountExplanation)
                        .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                        .styleGuide(.subheadline)
                }
            }
            .padding(12)
            .contentBlock()

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
                .buttonStyle(.secondary(isDestructive: true))
                .accessibilityIdentifier("CANCEL")
            }
        }
        .navigationBar(title: Localizations.deleteAccount, titleDisplayMode: .inline)
        .scrollView(padding: 12)
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
