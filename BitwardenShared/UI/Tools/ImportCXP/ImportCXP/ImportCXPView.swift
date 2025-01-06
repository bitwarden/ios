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
                    image: Image(decorative: store.state.mainIcon),
                    title: store.state.title,
                    message: store.state.message,
                    style: .largeWithTintedIcon
                )
                switch store.state.status {
                case .start:
                    EmptyView()
                case .importing:
                    ProgressView(value: store.state.progress)
                        .tint(Asset.Colors.tintPrimary.swiftUIColor)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: 1, y: 3, anchor: .center)
                        .accessibilityIdentifier("ImportProgress")
                case let .success(_, results):
                    VStack(spacing: 16) {
                        ForEach(results) { result in
                            importedTypeRow(result: result)
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
            .scrollView(backgroundColor: Asset.Colors.backgroundSecondary.swiftUIColor)
            .safeAreaInset(edge: .bottom) {
                VStack {
                    if store.state.showMainButton {
                        AsyncButton(store.state.mainButtonTitle) {
                            await store.perform(.mainButtonTapped)
                        }
                        .buttonStyle(.primary())
                        .accessibilityIdentifier("MainButton")
                    }

                    if store.state.showCancelButton {
                        AsyncButton(Localizations.cancel) {
                            await store.perform(.cancel)
                        }
                        .buttonStyle(.secondary())
                        .accessibilityIdentifier("CancelButton")
                    }
                }
                .padding(.horizontal, 16)
                .background(Asset.Colors.backgroundSecondary.swiftUIColor)
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

    /// The row for an imported type result.
    @ViewBuilder
    private func importedTypeRow(result: ImportedCredentialsResult) -> some View {
        HStack {
            Text(result.localizedTypePlural)
                .styleGuide(.body)
            Spacer()
            Text("\(result.count)")
                .styleGuide(.body)
                .accessibilityIdentifier("\(result.type)ImportTotal")
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Start") {
    ImportCXPView(store: Store(processor: StateProcessor(state: ImportCXPState())))
        .navStackWrapped
}

#Preview("Importing") {
    ImportCXPView(
        store: Store(
            processor: StateProcessor(
                state: ImportCXPState(
                    progress: 0.3,
                    status: .importing
                )
            )
        )
    ).navStackWrapped
}

#Preview("Success") {
    ImportCXPView(
        store: Store(
            processor: StateProcessor(
                state: ImportCXPState(
                    status: .success(
                        totalImportedCredentials: 30,
                        importedResults: [
                            ImportedCredentialsResult(count: 13, type: .password),
                            ImportedCredentialsResult(count: 7, type: .passkey),
                            ImportedCredentialsResult(count: 10, type: .card),
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
