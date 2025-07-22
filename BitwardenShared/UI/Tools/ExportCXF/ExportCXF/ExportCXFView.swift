import BitwardenResources
import SwiftUI

// MARK: - ExportCXFView

/// A view to export credentials in the Credential Exchange flow.
///
struct ExportCXFView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ExportCXFState, ExportCXFAction, ExportCXFEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            IllustratedMessageView(
                image: Image(decorative: store.state.mainIcon),
                style: .largeTextTintedIcon,
                title: store.state.title,
                message: store.state.message
            )
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity)

            if case .prepared = store.state.status {
                Text(Localizations.itemsToExport)
                    .styleGuide(.title, weight: .bold)
                    .padding(.horizontal, 20)
                    .accessibilityIdentifier("SectionTitle")
            }

            switch store.state.status {
            case .start:
                CircularActivityIndicator()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .prepared(results):
                VStack(spacing: 16) {
                    ForEach(results) { result in
                        exportingTypeRow(result: result)
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

                AsyncButton(Localizations.cancel) {
                    await store.perform(.cancel)
                }
                .buttonStyle(.secondary())
                .accessibilityIdentifier("CancelButton")
            }
            .padding(.horizontal, 12)
            .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: store.state.status)
        .task {
            await store.perform(.appeared)
        }
        .apply { view in
            if #available(iOS 16.0, *) {
                view.toolbar(.hidden)
            } else {
                view.navigationBarHidden(true)
            }
        }
    }

    // MARK: Private

    /// The row for an exporting type result.
    @ViewBuilder
    private func exportingTypeRow(result: CXFCredentialsResult) -> some View {
        HStack {
            Text(result.localizedTypePlural)
                .styleGuide(.body)
            Spacer()
            Text("\(result.count)")
                .styleGuide(.body)
                .accessibilityIdentifier("\(result.type)ExportTotal")
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Start") {
    ExportCXFView(
        store: Store(
            processor: StateProcessor(
                state: ExportCXFState()
            )
        )
    )
    .navStackWrapped
}

#Preview("Prepared") {
    ExportCXFView(
        store: Store(
            processor: StateProcessor(
                state: ExportCXFState(
                    status: .prepared(
                        itemsToExport: [
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
    ExportCXFView(
        store: Store(
            processor: StateProcessor(
                state: ExportCXFState(
                    status: .failure(
                        message: "Something went wrong"
                    )
                )
            )
        )
    ).navStackWrapped
}

#endif
