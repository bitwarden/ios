import BitwardenSdk
import SwiftUI

// MARK: - MainSendListView

/// The main content of the `SendListView`. Broken out into it's own view so that the
/// `isSearching` environment variable will work correctly.
///
private struct MainSendListView: View {
    // MARK: Properties

    /// A flag indicating if the search bar is focused.
    @Environment(\.isSearching) private var isSearching

    /// The `Store` for this view.
    @ObservedObject var store: Store<SendListState, SendListAction, SendListEffect>

    // MARK: View

    var body: some View {
        // A ZStack with hidden children is used here so that opening and closing the
        // search interface does not reset the scroll position for the main vault
        // view, as would happen if we used an `if else` block here.
        //
        // Additionally, we cannot use an `.overlay()` on the main vault view to contain
        // the search interface since VoiceOver still reads the elements below the overlay,
        // which is not ideal.

        ZStack {
            let isSearching = store.state.isSearching
                || !store.state.searchText.isEmpty
                || !store.state.searchResults.isEmpty

            content
                .hidden(isSearching)

            search
                .hidden(!isSearching)
        }
        .onChange(of: isSearching) { newValue in
            store.send(.searchStateChanged(isSearching: newValue))
        }
    }

    // MARK: Private views

    /// The view shown when not searching. Contains sends content or an empty state.
    @ViewBuilder private var content: some View {
        if store.state.sections.isEmpty {
            empty
        } else {
            list
        }
    }

    /// The empty state for this view, displayed when there are no items.
    @ViewBuilder private var empty: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 24) {
                    if store.state.isSendDisabled {
                        InfoContainer(Localizations.sendDisabledWarning)
                    }

                    Spacer()

                    Text(Localizations.noSends)
                        .multilineTextAlignment(.center)

                    Button(Localizations.addASend) {
                        store.send(.addItemPressed)
                    }
                    .buttonStyle(.tertiary())

                    Spacer()
                }
                .padding(16)
                .frame(minHeight: reader.size.height)
            }
            .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        }
    }

    /// The list for this view, displayed when there is content to display.
    @ViewBuilder private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if store.state.isSendDisabled {
                    InfoContainer(Localizations.sendDisabledWarning)
                }

                ForEach(store.state.sections) { section in
                    sendItemSectionView(
                        sectionName: section.name,
                        isCountDisplayed: section.isCountDisplayed,
                        items: section.items
                    )
                }
            }
            .padding(16)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
    }

    /// A view that displays the search interface, including search results, an empty search
    /// interface, and a message indicating that no results were found.
    @ViewBuilder private var search: some View {
        if store.state.searchText.isEmpty || !store.state.searchResults.isEmpty {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if !store.state.searchResults.isEmpty {
                        sendItemSectionView(
                            sectionName: nil,
                            isCountDisplayed: false,
                            items: store.state.searchResults
                        )
                    }
                }
                .padding(16)
            }
            .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        } else {
            SearchNoResultsView()
        }
    }

    /// Creates a section that appears in the sends list.
    ///
    /// - Parameters:
    ///   - sectionName: The title of the section.
    ///   - isCountDisplayed: A flag indicating if the count should be displayed
    ///     in this section's title.
    ///   - items: The `SendListItem`s in this section.
    ///
    @ViewBuilder
    private func sendItemSectionView(
        sectionName: String?,
        isCountDisplayed: Bool,
        items: [SendListItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            if sectionName != nil || isCountDisplayed {
                HStack(alignment: .firstTextBaseline) {
                    if let sectionName {
                        SectionHeaderView(sectionName)
                    }
                    Spacer()
                    if isCountDisplayed {
                        SectionHeaderView("\(items.count)")
                    }
                }
            }

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(items) { item in
                    SendListItemRowView(
                        store: store.child(
                            state: { _ in
                                SendListItemRowState(
                                    isSendDisabled: store.state.isSendDisabled,
                                    item: item,
                                    hasDivider: items.last != item
                                )
                            },
                            mapAction: SendListAction.sendListItemRow,
                            mapEffect: SendListEffect.sendListItemRow
                        )
                    )
                }
            }
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - SendListView

/// A view that allows the user to view a list of the send items.
///
struct SendListView: View {
    // MARK: Properties

    /// The GroupSearchDelegate used to bridge UIKit to SwiftUI
    var searchHandler: SendListSearchHandler?

    /// An action that opens URLs.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<SendListState, SendListAction, SendListEffect>

    // MARK: View

    var body: some View {
        MainSendListView(store: store)
            .searchable(
                text: store.binding(
                    get: \.searchText,
                    send: SendListAction.searchTextChanged
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Localizations.search
            )
            .refreshable { await store.perform(.refresh) }
            .navigationBar(
                title: store.state.navigationTitle,
                titleDisplayMode: store.state.type == nil ? .large : .inline
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !store.state.isInfoButtonHidden {
                        Button {
                            store.send(.infoButtonPressed)
                        } label: {
                            Image(asset: Asset.Images.infoRound, label: Text(Localizations.aboutSend))
                                .resizable()
                                .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                                .frame(width: 22, height: 22)
                        }
                        .frame(minHeight: 44)
                    }
                }

                addToolbarItem {
                    store.send(.addItemPressed)
                }
            }
            .toast(store.binding(
                get: \.toast,
                send: SendListAction.toastShown
            ))
            .task { await store.perform(.loadData) }
            .task { await store.perform(.streamSendList) }
            .task(id: store.state.searchText) {
                await store.perform(.search(store.state.searchText))
            }
            .onChange(of: store.state.infoUrl) { newValue in
                guard let url = newValue else { return }
                openURL(url)
                store.send(.clearInfoUrl)
            }
    }
}

// MARK: Previews

#Preview("Empty") {
    NavigationView {
        SendListView(
            store: Store(
                processor: StateProcessor(
                    state: SendListState()
                )
            )
        )
    }
}

#Preview("Sends") {
    NavigationView {
        SendListView(
            store: Store(
                processor: StateProcessor(
                    state: SendListState(
                        sections: [
                            SendListSection(
                                id: "1",
                                isCountDisplayed: false,
                                items: [
                                    SendListItem(
                                        id: "11",
                                        itemType: .group(.text, 42)
                                    ),
                                    SendListItem(
                                        id: "12",
                                        itemType: .group(.file, 1)
                                    ),
                                ],
                                name: "Types"
                            ),
                            SendListSection(
                                id: "2",
                                isCountDisplayed: true,
                                items: [
                                    SendListItem(
                                        sendView: .init(
                                            id: "21",
                                            accessId: "21",
                                            name: "File Send",
                                            notes: nil,
                                            key: "",
                                            newPassword: nil,
                                            hasPassword: false,
                                            type: .file,
                                            file: nil,
                                            text: nil,
                                            maxAccessCount: nil,
                                            accessCount: 0,
                                            disabled: false,
                                            hideEmail: false,
                                            revisionDate: Date(),
                                            deletionDate: Date().advanced(by: 100),
                                            expirationDate: Date().advanced(by: 100)
                                        )
                                    )!,
                                    SendListItem(
                                        sendView: .init(
                                            id: "22",
                                            accessId: "22",
                                            name: "Text Send",
                                            notes: nil,
                                            key: "",
                                            newPassword: nil,
                                            hasPassword: false,
                                            type: .text,
                                            file: nil,
                                            text: nil,
                                            maxAccessCount: nil,
                                            accessCount: 0,
                                            disabled: false,
                                            hideEmail: false,
                                            revisionDate: Date(),
                                            deletionDate: Date().advanced(by: 100),
                                            expirationDate: Date().advanced(by: 100)
                                        )
                                    )!,
                                    SendListItem(
                                        sendView: .init(
                                            id: "23",
                                            accessId: "23",
                                            name: "All Statuses",
                                            notes: nil,
                                            key: "",
                                            newPassword: nil,
                                            hasPassword: true,
                                            type: .text,
                                            file: nil,
                                            text: nil,
                                            maxAccessCount: 1,
                                            accessCount: 1,
                                            disabled: true,
                                            hideEmail: true,
                                            revisionDate: Date(),
                                            deletionDate: Date(),
                                            expirationDate: Date().advanced(by: -1)
                                        )
                                    )!,
                                ],
                                name: "All sends"
                            ),
                        ]
                    )
                )
            )
        )
    }
}

#Preview("Search - Empty") {
    NavigationView {
        SendListView(
            store: Store(
                processor: StateProcessor(
                    state: SendListState(
                        searchText: "Searching",
                        searchResults: []
                    )
                )
            )
        )
    }
}

#Preview("Search - Results") {
    NavigationView {
        SendListView(
            store: Store(
                processor: StateProcessor(
                    state: SendListState(
                        searchText: "Searching",
                        searchResults: [
                            SendListItem(
                                sendView: .init(
                                    id: "22",
                                    accessId: "22",
                                    name: "Text Send",
                                    notes: nil,
                                    key: "",
                                    newPassword: nil,
                                    hasPassword: false,
                                    type: .text,
                                    file: nil,
                                    text: nil,
                                    maxAccessCount: nil,
                                    accessCount: 0,
                                    disabled: false,
                                    hideEmail: false,
                                    revisionDate: Date(),
                                    deletionDate: Date().advanced(by: 100),
                                    expirationDate: Date().advanced(by: 100)
                                )
                            )!,
                            SendListItem(
                                sendView: .init(
                                    id: "23",
                                    accessId: "23",
                                    name: "All Statuses",
                                    notes: nil,
                                    key: "",
                                    newPassword: nil,
                                    hasPassword: true,
                                    type: .text,
                                    file: nil,
                                    text: nil,
                                    maxAccessCount: 1,
                                    accessCount: 1,
                                    disabled: true,
                                    hideEmail: true,
                                    revisionDate: Date(),
                                    deletionDate: Date(),
                                    expirationDate: Date().advanced(by: -1)
                                )
                            )!,
                        ]
                    )
                )
            )
        )
    }
} // swiftlint:disable:this file_length
