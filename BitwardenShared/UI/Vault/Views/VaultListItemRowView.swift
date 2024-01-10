import BitwardenSdk
import SwiftUI

// MARK: - VaultListItemRowState

/// An object representing the visual state of a `VaultListItemRowView`.
struct VaultListItemRowState {
    // MARK: Properties

    /// The item displayed in this row.
    var item: VaultListItem

    /// A flag indicating if this row should display a divider on the bottom edge.
    var hasDivider: Bool
}

// MARK: - VaultListItemRowAction

/// Actions that can be sent from a `VaultListItemRowView`.
enum VaultListItemRowAction: Equatable {
    /// The copy TOTP Code button was pressed.
    ///
    case copyTOTPCode(_ code: String)
}

enum VaultListItemRowEffect {
    /// The more button was pressed.
    ///
    case morePressed
}

// MARK: - VaultListItemRowView

/// A view that displays information about a `VaultListItem` as a row in a list.
struct VaultListItemRowView: View {
    // MARK: Properties

    /// The `Store` for this view.
    var store: Store<VaultListItemRowState, VaultListItemRowAction, VaultListItemRowEffect>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                if case let .totp(_, model) = store.state.item.itemType {
                    AsyncImage(
                        url: IconImageHelper.getIconImage(
                            for: model.loginView,
                            from: model.iconBaseURL
                        ),
                        content: { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                .padding(.vertical, 19)
                        },
                        placeholder: {
                            Image(decorative: store.state.item.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                .padding(.vertical, 19)
                        }
                    )
                } else {
                    Image(decorative: store.state.item.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                        .padding(.vertical, 19)
                }
                HStack {
                    switch store.state.item.itemType {
                    case let .cipher(cipherItem):
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 8) {
                                Text(cipherItem.name)
                                    .styleGuide(.body)
                                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                                    .lineLimit(1)

                                if cipherItem.organizationId != nil {
                                    Asset.Images.collections.swiftUIImage
                                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                        .accessibilityLabel(Localizations.shared)
                                }
                            }

                            if let subTitle = cipherItem.subTitle.nilIfEmpty {
                                Text(subTitle)
                                    .styleGuide(.subheadline)
                                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                    .lineLimit(1)
                            }
                        }
                        .accessibilityElement(children: .combine)

                        Spacer()

                        AsyncButton {
                            await store.perform(.morePressed)
                        } label: {
                            Asset.Images.horizontalKabob.swiftUIImage
                        }
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                        .accessibilityLabel(Localizations.more)

                    case let .group(group, count):
                        Text(group.name)
                            .styleGuide(.body)
                            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        Spacer()
                        Text("\(count)")
                            .styleGuide(.body)
                            .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    case let .totp(_, model):
                        totpCodeRow(model)
                    }
                }
                .padding(.vertical, 9)
            }
            .padding(.horizontal, 16)

            if store.state.hasDivider {
                Divider()
                    .padding(.leading, 22 + 16 + 16)
            }
        }
    }

    @ViewBuilder
    private func totpCodeRow(_ model: VaultListTOTP) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let uri = model.loginView.uris?.first?.uri {
                Text(uri)
                    .styleGuide(.body)
                    .lineLimit(1)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
            }
            if let username = model.loginView.username {
                Text(username)
                    .styleGuide(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
            }
        }
        Spacer()
        TOTPCountdownTimerView(
            totpCode: model.totpCode,
            onExpiration: nil
        )
        Text(model.totpCode.displayCode)
            .styleGuide(.bodyMonospaced, weight: .regular, monoSpacedDigit: true)
            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
        Button {
            Task { @MainActor in
                store.send(.copyTOTPCode(model.totpCode.code))
            }
        } label: {
            Asset.Images.copy.swiftUIImage
        }
        .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
        .accessibilityLabel(Localizations.copyTotp)
    }
}
