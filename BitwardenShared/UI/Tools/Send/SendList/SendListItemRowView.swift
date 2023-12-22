import BitwardenSdk
import SwiftUI

// MARK: - VaultListItemRowState

/// An object representing the visual state of a `VaultListItemRowView`.
struct SendListItemRowState: Equatable {
    // MARK: Properties

    /// The item displayed in this row.
    var item: SendListItem

    /// A flag indicating if this row should display a divider on the bottom edge.
    var hasDivider: Bool
}

// MARK: - VaultListItemRowAction

/// Actions that can be sent from a `SendListItemRowView`.
enum SendListItemRowAction: Equatable {
    /// The item was pressed.
    case sendListItemPressed(SendListItem)
}

// MARK: - SendListItemView

struct SendListItemRowView: View {
    // MARK: Properties

    /// The `Store` for this view.
    var store: Store<SendListItemRowState, SendListItemRowAction, Void>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                Button {
                    store.send(.sendListItemPressed(store.state.item))
                } label: {
                    HStack(spacing: 16) {
                        Image(decorative: store.state.item.icon)
                            .resizable()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                            .padding(.vertical, 19)

                        switch store.state.item.itemType {
                        case let .send(sendListView):
                            VStack(alignment: .leading, spacing: 0) {
                                Text(sendListView.name)
                                    .styleGuide(.body)
                                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)

                                Text(sendListView.revisionDate.formatted(date: .abbreviated, time: .shortened))
                                    .styleGuide(.subheadline)
                                    .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                            }

                            Spacer()

                        case let .group(sendType, count):
                            Text(sendType.localizedName)
                                .styleGuide(.body)
                                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)

                            Spacer()

                            Text("\(count)")
                                .styleGuide(.body)
                                .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                        }
                    }
                    .padding(.vertical, 9)
                }

                Menu {
                    // TODO: BIT-1266 Add Menu items
                    Text("Coming soon, in BIT-1266")
                } label: {
                    Asset.Images.horizontalKabob.swiftUIImage
                        .resizable()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                }
            }
            .padding(.horizontal, 16)

            if store.state.hasDivider {
                Divider()
                    .padding(.leading, 22 + 16 + 16)
            }
        }
    }
}

//#Preview {
//    VStack {
//        SendListItemView(
//            action: {},
//            item: SendListItem(id: "1", itemType: .group(.text, 42)),
//            hasDivider: true
//        )
//        SendListItemView(action: {}, item: SendListItem(id: "2", itemType: .group(.file, 42)))
//        SendListItemView(
//            action: {},
//            item: SendListItem(
//                id: "3",
//                itemType: .send(BitwardenSdk.SendListView(
//                    id: "3",
//                    accessId: "3",
//                    name: "File Name",
//                    type: .file,
//                    disabled: false,
//                    revisionDate: Date(),
//                    deletionDate: Date(),
//                    expirationDate: Date()
//                ))
//            )
//        )
//        SendListItemView(
//            action: {},
//            item: SendListItem(
//                id: "4",
//                itemType: .send(BitwardenSdk.SendListView(
//                    id: "4",
//                    accessId: "4",
//                    name: "Text Name", 
//                    type: .text,
//                    disabled: false,
//                    revisionDate: Date(),
//                    deletionDate: Date(),
//                    expirationDate: Date()
//                ))
//            )
//        )
//    }
//}
