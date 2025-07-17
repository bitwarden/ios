import BitwardenResources
@preconcurrency import BitwardenSdk
import SwiftUI

// MARK: - SendListItemRowState

/// An object representing the visual state of a `SendListItemRowState`.
struct SendListItemRowState: Equatable {
    // MARK: Properties

    /// The accessibility identifier for the `SendListItem`.
    var accessibilityIdentifier: String {
        switch item.itemType {
        case .send:
            return "SendCell"
        case let .group(type, _):
            switch type {
            case .text:
                return "SendTextFilter"
            case .file:
                return "SendFileFilter"
            }
        }
    }

    /// Whether sends are disabled via a policy.
    var isSendDisabled = false

    /// The item displayed in this row.
    var item: SendListItem

    /// A flag indicating if this row should display a divider on the bottom edge.
    var hasDivider: Bool
}

// MARK: - SendListItemRowAction

/// Actions that can be sent from a `SendListItemRowView`.
enum SendListItemRowAction: Equatable, Sendable {
    /// The edit button was pressed.
    case editPressed(_ sendView: SendView)

    /// The item was pressed.
    case sendListItemPressed(SendListItem)

    /// The view send button was tapped.
    case viewSend(_ sendView: SendView)
}

// MARK: - SendListItemRowEffect

enum SendListItemRowEffect: Equatable, Sendable {
    /// The copy link button was pressed.
    case copyLinkPressed(_ sendView: SendView)

    /// The delete button was pressed.
    case deletePressed(_ sendView: SendView)

    /// The remove password button was pressed.
    case removePassword(_ sendView: SendView)

    /// The share link button was pressed.
    case shareLinkPressed(_ sendView: SendView)
}

// MARK: - SendListItemView

/// A view that displays details about a `SendListItem`, to be used as a row in a list.
///
struct SendListItemRowView: View {
    // MARK: Private Properties

    /// The width of the icon displayed on the leading edge of the screen, scaled to match
    /// DynamicType.
    @ScaledMetric private var scaledIconWidth = 22

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<SendListItemRowState, SendListItemRowAction, SendListItemRowEffect>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                Button {
                    store.send(.sendListItemPressed(store.state.item))
                } label: {
                    buttonLabel(for: store.state.item)
                }
                .accessibilityIdentifier(store.state.accessibilityIdentifier)

                if case let .send(sendView) = store.state.item.itemType {
                    optionsMenu(for: sendView)
                }
            }
            .padding(.horizontal, 16)

            if store.state.hasDivider {
                Divider()
                    .padding(.leading, scaledIconWidth + 16 + 16)
            }
        }
    }

    // MARK: Private Views

    /// The button's label for the specified send.
    ///
    /// - Parameter item: The `SendListItem` to display.
    ///
    @ViewBuilder
    private func buttonLabel(for item: SendListItem) -> some View {
        HStack(spacing: 16) {
            Image(decorative: item.icon)
                .scaledFrame(width: 22, height: 22)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .padding(.vertical, 19)

            switch item.itemType {
            case let .send(sendView):
                sendLabel(for: sendView)
            case let .group(sendType, count):
                groupLabel(for: sendType, count: count)
            }
        }
    }

    /// The label for a group.
    ///
    /// - Parameters:
    ///   - sendType: The type of sends this group represents.
    ///   - count: The number of sends in this group.
    ///
    @ViewBuilder
    private func groupLabel(for sendType: SendType, count: Int) -> some View {
        Text(sendType.localizedName)
            .styleGuide(.body)
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

        Spacer()

        Text("\(count)")
            .styleGuide(.body)
            .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
    }

    /// An options menu to display for a send.
    ///
    /// - Parameter sendView: The `SendView` to display a menu for.
    ///
    @ViewBuilder
    private func optionsMenu(for sendView: SendView) -> some View {
        Menu {
            if !store.state.isSendDisabled {
                AsyncButton(Localizations.copyLink) {
                    await store.perform(.copyLinkPressed(sendView))
                }
                .accessibilityIdentifier("Copy")
                AsyncButton(Localizations.shareLink) {
                    await store.perform(.shareLinkPressed(sendView))
                }

                Section("") {
                    Button(Localizations.view) {
                        store.send(.viewSend(sendView))
                    }
                    Button(Localizations.edit) {
                        store.send(.editPressed(sendView))
                    }
                    if sendView.hasPassword {
                        AsyncButton(Localizations.removePassword) {
                            await store.perform(.removePassword(sendView))
                        }
                    }

                    AsyncButton(Localizations.delete, role: .destructive) {
                        await store.perform(.deletePressed(sendView))
                    }
                }
            } else {
                AsyncButton(Localizations.delete, role: .destructive) {
                    await store.perform(.deletePressed(sendView))
                }
            }

        } label: {
            Asset.Images.ellipsisHorizontal24.swiftUIImage
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
        }
        .accessibilityIdentifier("SendOptionsButton")
    }

    /// The label for a send.
    ///
    /// - Parameter sendView: The `SendView` to display.
    ///
    @ViewBuilder
    private func sendLabel(for sendView: SendView) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            AccessibleHStack(alignment: .leading, spacing: 8) {
                Text(sendView.name)
                    .styleGuide(.body)
                    .lineLimit(1)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("SendNameLabel")

                iconStack(for: sendView)
            }

            Text(sendView.deletionDate.dateTimeDisplay)
                .styleGuide(.subheadline)
                .lineLimit(1)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .accessibilityIdentifier("SendDateLabel")
        }
        .padding(.vertical, 9)

        Spacer()
    }

    private func icons(
        for sendView: SendView
    ) -> [[SendListItemIcon]] {
        var icons: [SendListItemIcon] = []
        if sendView.disabled {
            icons.append(
                SendListItemIcon(
                    accessibilityID: "DisabledSendIcon",
                    asset: Asset.Images.warning16.swiftUIImage
                )
            )
        }

        if sendView.hasPassword {
            icons.append(
                SendListItemIcon(
                    accessibilityID: "PasswordProtectedSendIcon",
                    asset: Asset.Images.key16.swiftUIImage
                )
            )
        }

        if let maxAccessCount = sendView.maxAccessCount,
           sendView.accessCount >= maxAccessCount {
            icons.append(
                SendListItemIcon(
                    accessibilityID: "MaxAccessSendIcon",
                    asset: Asset.Images.doNot16.swiftUIImage
                )
            )
        }

        if let expirationDate = sendView.expirationDate, expirationDate < Date() {
            icons.append(
                SendListItemIcon(
                    accessibilityID: "ExpiredSendIcon",
                    asset: Asset.Images.clock16.swiftUIImage
                )
            )
        }

        if sendView.deletionDate < Date() {
            icons.append(
                SendListItemIcon(
                    accessibilityID: "PendingDeletionSendIcon",
                    asset: Asset.Images.trash16.swiftUIImage
                )
            )
        }

        let groupedIcons = stride(from: icons.startIndex, to: icons.endIndex, by: 3)
            .map { index in
                Array(icons[index ..< min(index + 3, icons.endIndex)])
            }
        return groupedIcons
    }

    @ViewBuilder
    private func iconStack(for sendView: SendView) -> some View {
        AccessibleHStack(alignment: .leading, spacing: 8, minVerticalDynamicTypeSize: .accessibility3) {
            ForEachIndexed(icons(for: sendView), id: \.self) { _, row in
                HStack(spacing: 8) {
                    ForEachIndexed(row, id: \.self) { _, image in
                        image.asset
                            .scaledFrame(width: 16, height: 16)
                            .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                            .accessibilityIdentifier(image.accessibilityID)
                    }
                }
            }
        }
    }
}

// MARK: - SendListItemIcon

/// An icon used in the `SendListItemRowView`.
///
struct SendListItemIcon: Hashable {
    /// The icon's accessibility ID.
    let accessibilityID: String

    /// The asset for the icon.
    let asset: Image

    func hash(into hasher: inout Hasher) {
        hasher.combine(accessibilityID)
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    VStack {
        SendListItemRowView(
            store: Store(
                processor: StateProcessor(
                    state: SendListItemRowState(
                        item: SendListItem(id: "1", itemType: .group(.text, 42)),
                        hasDivider: true
                    )
                )
            )
        )
        SendListItemRowView(
            store: Store(
                processor: StateProcessor(
                    state: SendListItemRowState(
                        item: SendListItem(id: "1", itemType: .group(.file, 42)),
                        hasDivider: true
                    )
                )
            )
        )
        SendListItemRowView(
            store: Store(
                processor: StateProcessor(
                    state: SendListItemRowState(
                        item: SendListItem(
                            id: "3",
                            itemType: .send(.fixture(
                                id: "3",
                                name: "All Statuses",
                                hasPassword: true,
                                type: .text,
                                maxAccessCount: 1,
                                accessCount: 1,
                                disabled: true,
                                deletionDate: Date(),
                                expirationDate: Date().advanced(by: -1)
                            ))
                        ),
                        hasDivider: true
                    )
                )
            )
        )
        SendListItemRowView(
            store: Store(
                processor: StateProcessor(
                    state: SendListItemRowState(
                        item: SendListItem(
                            id: "4",
                            itemType: .send(.fixture(
                                id: "4",
                                name: "No Status",
                                deletionDate: Date().advanced(by: 100),
                                expirationDate: Date().advanced(by: 100)
                            ))
                        ),
                        hasDivider: false
                    )
                )
            )
        )
    }
}
#endif
