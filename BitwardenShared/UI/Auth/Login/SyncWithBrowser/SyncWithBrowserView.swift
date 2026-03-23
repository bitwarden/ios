import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - SyncWithBrowserView

/// A view shown when the app needs the user to sync SSO authentication through
/// their default browser.
///
struct SyncWithBrowserView: View {
    // MARK: Properties

    /// An object used to open URLs from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<SyncWithBrowserState, SyncWithBrowserAction, SyncWithBrowserEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 24) {
            IllustratedMessageView(
                image: Asset.Images.Illustrations.keyhole,
                style: .smallImage,
                title: Localizations.syncWithBrowser,
                message: Localizations.syncWithBrowserDescriptionLong(store.state.environmentUrl),
            )

            VStack(spacing: 12) {
                AsyncButton {
                    await store.perform(.launchBrowserTapped)
                } label: {
                    Label(Localizations.launchBrowser, image: SharedAsset.Icons.externalLink16.swiftUIImage)
                }
                .buttonStyle(.primary())

                Button(Localizations.continueWithoutSyncing) {
                    store.send(.continueWithoutSyncingTapped)
                }
                .buttonStyle(.secondary())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
        .scrollView()
        .dismissKeyboardOnAppear()
        .task {
            await store.perform(.appeared)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    SyncWithBrowserView(
        store: Store(
            processor: StateProcessor(
                state: SyncWithBrowserState(
                    environmentUrl: "https://example.bitwarden.com",
                ),
            ),
        ),
    )
    .navStackWrapped
}
#endif
