import BitwardenResources
import SwiftUI

// MARK: - ImportCXFView

/// A view to import credentials in the Credential Exchange protocol flow.
///
struct ImportCXFView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ImportCXFState, Void, ImportCXFEffect>

    // MARK: View

    var body: some View {
        Group {
            VStack(spacing: 16) {
                IllustratedMessageView(
                    image: Image(decorative: store.state.mainIcon),
                    style: .largeTextTintedIcon,
                    title: store.state.title,
                    message: store.state.message
                )
                switch store.state.status {
                case .start:
                    EmptyView()
                case .importing:
                    ProgressView(value: store.state.progress)
                        .tint(SharedAsset.Colors.tintPrimary.swiftUIColor)
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
            .scrollView(backgroundColor: SharedAsset.Colors.backgroundSecondary.swiftUIColor)
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
                .padding(.horizontal, 12)
                .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
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
    private func importedTypeRow(result: CXFCredentialsResult) -> some View {
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
    ImportCXFView(store: Store(processor: StateProcessor(state: ImportCXFState())))
        .navStackWrapped
}

#Preview("Importing") {
    ImportCXFView(
        store: Store(
            processor: StateProcessor(
                state: ImportCXFState(
                    progress: 0.3,
                    status: .importing
                )
            )
        )
    ).navStackWrapped
}

#Preview("Success") {
    ImportCXFView(
        store: Store(
            processor: StateProcessor(
                state: ImportCXFState(
                    status: .success(
                        totalImportedCredentials: 30,
                        importedResults: [
                            CXFCredentialsResult(count: 13, type: .password),
                            CXFCredentialsResult(count: 7, type: .passkey),
                            CXFCredentialsResult(count: 10, type: .card),
                        ]
                    )
                )
            )
        )
    ).navStackWrapped
}

#Preview("Failure") {
    ImportCXFView(
        store: Store(
            processor: StateProcessor(
                state: ImportCXFState(
                    status: .failure(
                        message: "Something went wrong"
                    )
                )
            )
        )
    ).navStackWrapped
}

#endif
