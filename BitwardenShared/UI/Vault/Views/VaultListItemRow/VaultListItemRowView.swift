import BitwardenSdk
import SwiftUI

// MARK: - VaultListItemRowView

/// A view that displays information about a `VaultListItem` as a row in a list.
struct VaultListItemRowView: View {
    // MARK: Properties

    /// The `Store` for this view.
    var store: Store<VaultListItemRowState, VaultListItemRowAction, Void>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                decorativeImage(
                    store.state.item,
                    iconBaseURL: store.state.iconBaseURL,
                    showWebIcons: store.state.showWebIcons
                )
                .frame(width: 22, height: 22)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                .padding(.vertical, 19)
                .accessibilityHidden(true)

                HStack {
                    switch store.state.item.itemType {
                    case let .cipher(cipherItem):
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 8) {
                                Text(cipherItem.name)
                                    .styleGuide(.body)
                                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                                    .lineLimit(1)
                                    .accessibilityIdentifier("CipherNameLabel")

                                if cipherItem.organizationId != nil {
                                    Asset.Images.collections.swiftUIImage
                                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                        .accessibilityLabel(Localizations.shared)
                                        .accessibilityIdentifier("CipherInCollectionIcon")
                                }

                                if cipherItem.attachments?.isEmpty == false {
                                    Asset.Images.paperclip.swiftUIImage
                                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                        .accessibilityLabel(Localizations.attachments)
                                        .accessibilityIdentifier("CipherWithAttachmentsIcon")
                                }
                            }

                            if let subTitle = store.state.item.subtitle, !subTitle.isEmpty {
                                Text(subTitle)
                                    .styleGuide(.subheadline)
                                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                    .lineLimit(1)
                                    .accessibilityIdentifier("CipherSubTitleLabel")
                            }
                        }
                        .accessibilityElement(children: .combine)

                        Spacer()

                        Button {
                            store.send(.morePressed)
                        } label: {
                            Asset.Images.horizontalKabob.swiftUIImage
                        }
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                        .accessibilityLabel(Localizations.more)
                        .accessibilityIdentifier("CipherOptionsButton")

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

    // MARK: - Private Views

    /// The decorative image for the row.
    ///
    /// - Parameters:
    ///   - item: The item in the row.
    ///   - iconBaseURL: The base url used to download decorative images.
    ///   - showWebIcons: Whether to download the web icons.
    ///
    @ViewBuilder
    private func decorativeImage(_ item: VaultListItem, iconBaseURL: URL?, showWebIcons: Bool) -> some View {
        if showWebIcons, let loginView = item.loginView, let iconBaseURL {
            AsyncImage(
                url: IconImageHelper.getIconImage(
                    for: loginView,
                    from: iconBaseURL
                ),
                content: { image in
                    image
                        .resizable()
                        .scaledToFit()
                },
                placeholder: {
                    placeholderDecorativeImage(item.icon)
                }
            )
        } else {
            placeholderDecorativeImage(item.icon)
        }
    }

    /// The placeholder image for the decorative image.
    private func placeholderDecorativeImage(_ icon: ImageAsset) -> some View {
        Image(decorative: icon)
            .resizable()
            .scaledToFit()
    }

    /// The row showing the totp code.
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
            timeProvider: timeProvider,
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
