import SwiftUI

// MARK: - ViewSendItemView

/// A view that allows the user to view the details of a send item.
///
struct ViewSendItemView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewSendItemState, ViewSendItemAction, ViewSendItemEffect>

    // MARK: View

    var body: some View {
        content
            .scrollView(padding: 12)
            .navigationBar(title: store.state.navigationTitle, titleDisplayMode: .inline)
            .overlay(alignment: .bottomTrailing) {
                editItemFloatingActionButton {
                    store.send(.editItem)
                }
            }
            .task { await store.perform(.loadData) }
            .toast(
                store.binding(
                    get: \.toast,
                    send: ViewSendItemAction.toastShown
                ),
                additionalBottomPadding: FloatingActionButton.bottomOffsetPadding
            )
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismiss)
                }
            }
    }

    // MARK: Private Views

    /// The main content of the view.
    @ViewBuilder private var content: some View {
        VStack(spacing: 16) {
            sendLink
        }
    }

    /// The card containing the send link with copy and share buttons.
    @ViewBuilder private var sendLink: some View {
        ContentBlock {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localizations.sendLink)
                    .styleGuide(.title3, weight: .bold, includeLinePadding: false, includeLineSpacing: false)
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)

                if let displayShareURL = store.state.displayShareURL {
                    Text(displayShareURL)
                        .styleGuide(.subheadline)
                        .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                        .lineLimit(1)
                }
            }
            .padding(16)

            VStack(spacing: 12) {
                Button {
                    store.send(.copyShareURL)
                } label: {
                    Label(Localizations.copy, image: Asset.Images.copy16.swiftUIImage, scaleImageDimension: 16)
                }
                .buttonStyle(.primary())

                Button {
                    store.send(.shareSend)
                } label: {
                    Label(Localizations.share, image: Asset.Images.share16.swiftUIImage, scaleImageDimension: 16)
                }
                .buttonStyle(.secondary())
            }
            .padding(16)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Text") {
    ViewSendItemView(store: Store(processor: StateProcessor(state: ViewSendItemState(
        sendView: .fixture(),
        shareURL: URL(string: "https://send.bitwarden.com/39ngaol3")
    ))))
    .navStackWrapped
}

#Preview("File") {
    ViewSendItemView(store: Store(processor: StateProcessor(state: ViewSendItemState(
        sendView: .fixture(type: .file),
        shareURL: URL(string: "https://send.bitwarden.com/39ngaol3")
    ))))
    .navStackWrapped
}
#endif
