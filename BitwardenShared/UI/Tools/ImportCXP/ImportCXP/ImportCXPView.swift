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
        Group {
            VStack(spacing: 16) {
                PageHeaderView(
                    image: Asset.Images.Illustrations.import,
                    title: store.state.title,
                    message: store.state.message,
                    style: .large
                )
                switch store.state.status {
                case .start:
                    EmptyView()
                case .importing:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                case let .success(_, countByType):
                    VStack(spacing: 16) {
                        ForEach(countByType) { type in
                            HStack {
                                Text(type.localizedType)
                                    .styleGuide(.body)
                                Spacer()
                                Text("\(type.count)")
                                    .styleGuide(.body)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                case .failure:
                    EmptyView()
                }
            }
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
            .scrollView()
            .safeAreaInset(edge: .bottom) {
                VStack {
                    if store.state.showMainButton {
                        AsyncButton(store.state.mainButtonTitle) {
                            await store.perform(.mainButtonTapped)
                        }
                        .buttonStyle(.primary())
                    }

                    if store.state.showCancelButton {
                        AsyncButton(Localizations.cancel) {
                            await store.perform(.cancel)
                        }
                        .buttonStyle(.secondary())
                    }
                }
                .padding(.horizontal, 16)
                .background(Asset.Colors.backgroundPrimary.swiftUIColor)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: store.state.status)
        .task {
            await store.perform(.appeared)
        }
        .apply { view in
            if #available(iOSApplicationExtension 16.0, *) {
                view.toolbar(.hidden)
            } else {
                view.navigationBarHidden(true)
            }
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
