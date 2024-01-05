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
                        case let .send(sendView):
                            VStack(alignment: .leading, spacing: 0) {
                                AccessibleHStack(alignment: .leading, spacing: 8) {
                                    Text(sendView.name)
                                        .styleGuide(.body)
                                        .lineLimit(1)
                                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)

                                    HStack(spacing: 8) {
                                        if sendView.disabled {
                                            Asset.Images.exclamationTriangle.swiftUIImage
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                                .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                                        }

                                        if !sendView.password.isEmptyOrNil {
                                            Asset.Images.key.swiftUIImage
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                                .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                                        }

                                        if let maxAccessCount = sendView.maxAccessCount,
                                           sendView.accessCount >= maxAccessCount {
                                            Asset.Images.doNot.swiftUIImage
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                                .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                                        }

                                        if let expirationDate = sendView.expirationDate, expirationDate < Date() {
                                            Asset.Images.clock.swiftUIImage
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                                .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                                        }

                                        if sendView.deletionDate < Date() {
                                            Asset.Images.trash.swiftUIImage
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                                .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                                        }
                                    }
                                }

                                Text(sendView.revisionDate.formatted(date: .abbreviated, time: .shortened))
                                    .styleGuide(.subheadline)
                                    .lineLimit(1)
                                    .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                            }
                            .padding(.vertical, 9)

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
                            itemType: .send(.init(
                                id: "3",
                                accessId: "3",
                                name: "All Statuses",
                                notes: nil,
                                key: "",
                                password: "password",
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
                            itemType: .send(.init(
                                id: "4",
                                accessId: "4",
                                name: "No Status",
                                notes: nil,
                                key: "",
                                password: nil,
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
                            ))
                        ),
                        hasDivider: false
                    )
                )
            )
        )
    }
}
