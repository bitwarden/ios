import SwiftUI

// MARK: - ImportCXPView

/// A view to import credentials in the Credential Exchange protocol flow.
///
struct ImportCXPView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ImportCXPState, Void, ImportCXPEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            PageHeaderView(
                image: Asset.Images.Illustrations.import,
                title: store.state.title,
                message: store.state.message
            )
            switch store.state.status {
            case .start:
                Spacer()
                AsyncButton(Localizations.continue) {
                    await store.perform(.startImport)
                }
                .buttonStyle(.primary())
                AsyncButton(Localizations.cancel) {
                    await store.perform(.cancel)
                }
                .buttonStyle(.secondary())
            case .importing:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case let .success(_, countByType):
                VStack(spacing: 8) {
                    ForEach(countByType) { type in
                        HStack {
                            Text(type.localizedType)
                            Spacer()
                            Text("\(type.count)")
                        }
                    }
                }
                Spacer()
                AsyncButton(Localizations.showVault) {
                    await store.perform(.showVault)
                }
            case .failure:
                Spacer()
                AsyncButton(Localizations.retryImport) {
                    await store.perform(.startImport)
                }
                .buttonStyle(.primary())
                AsyncButton(Localizations.cancel) {
                    await store.perform(.cancel)
                }
                .buttonStyle(.secondary())
            }
        }
        .padding(.top, 8)
        .transition(.opacity)
//        .animation(.easeInOut, value: store.state.page)
        .navigationBar(title: Localizations.importPasswords, titleDisplayMode: .inline)
//        .toolbar {
//            cancelToolbarItem {
//                store.send(.dismiss)
//            }
//        }
        .task {
            await store.perform(.appeared)
        }
    }

    // MARK: Private
}

// MARK: - Previews

#if DEBUG
#Preview("Start") {
    ImportCXPView(store: Store(processor: StateProcessor(state: ImportCXPState())))
        .navStackWrapped
}

#Preview("Importing") {
    ImportCXPView(store: Store(processor: StateProcessor(state: ImportCXPState(status: .importing))))
        .navStackWrapped
}

#Preview("Success") {
    ImportCXPView(
        store: Store(
            processor: StateProcessor(
                state: ImportCXPState(
                    status: .success(
                        totalImportedCredentials: 30,
                        credentialsByTypeCount: [
                            ImportedCredentialsResult(localizedType: "Passwords", count: 13),
                            ImportedCredentialsResult(localizedType: "Passkeys", count: 7),
                            ImportedCredentialsResult(localizedType: "Cards", count: 10),
                        ]
                    )
                )
            )
        )
    ).navStackWrapped
}

#Preview("Failure") {
    ImportCXPView(
        store: Store(
            processor: StateProcessor(
                state: ImportCXPState(
                    status: .failure(
                        message: "Something went wrong"
                    )
                )
            )
        )
    ).navStackWrapped
}
#endif
