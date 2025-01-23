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
            if store.state.shouldPreventUserFromDeletingAccount {
                preventAccountDeletionSection
            } else {
                deleteAccountSection
            }
        }
        .navigationBar(title: Localizations.deleteAccount, titleDisplayMode: .inline)
        .scrollView()
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
        .task {
            await store.perform(.loadData)
        }
    }

    /// The other section.
    private var deleteAccountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(asset: Asset.Images.warning24)
                .foregroundColor(Color(asset: Asset.Colors.error))

            Text(Localizations.deletingYourAccountIsPermanent)
                .foregroundColor(Color(asset: Asset.Colors.error))
                .styleGuide(.headline, weight: .semibold)

            Text(Localizations.deleteAccountExplanation)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .styleGuide(.subheadline)

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

    /// The other section.
    private var preventAccountDeletionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(asset: Asset.Images.circleX16)
                .foregroundColor(Color(asset: Asset.Colors.error))

            Text(Localizations.cannotDeleteAccount)
                .foregroundColor(Color(asset: Asset.Colors.error))
                .styleGuide(.headline, weight: .semibold)

            Text(Localizations.cannotDeleteAccountDescription)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .styleGuide(.subheadline)

            Button {
                store.send(.dismiss)
            } label: {
                Text(Localizations.close)
            }
            .buttonStyle(.secondary(isDestructive: true))
            .accessibilityIdentifier("CLOSE")
        }
    }
}

// MARK: Previews

#Preview {
    DeleteAccountView(store: Store(processor: StateProcessor(state: DeleteAccountState())))
}
