import SwiftUI

// MARK: - ImportLoginsView

/// A view that instructs the user how to import their logins from another password manager.
///
struct ImportLoginsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ImportLoginsState, ImportLoginsAction, ImportLoginsEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 32) {
            PageHeaderView(
                image: Asset.Images.import,
                title: Localizations.giveYourVaultAHeadStart,
                message: Localizations.importLoginsDescriptionLong
            )

            VStack(spacing: 12) {
                Button(Localizations.getStarted) {
                    store.send(.getStarted)
                }
                .buttonStyle(.primary())

                AsyncButton(Localizations.importLoginsLater) {
                    await store.perform(.importLoginsLater)
                }
                .buttonStyle(.transparent)
            }
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
        .scrollView()
        .navigationBar(title: Localizations.importLogins, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    ImportLoginsView(store: Store(processor: StateProcessor(state: ImportLoginsState())))
        .navStackWrapped
}
#endif
