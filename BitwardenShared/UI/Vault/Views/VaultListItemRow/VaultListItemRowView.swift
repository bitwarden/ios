import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - VaultListItemRowView

/// A view that displays information about a `VaultListItem` as a row in a list.
struct VaultListItemRowView: View {
    // MARK: Properties

    /// The `Store` for this view.
    var store: Store<VaultListItemRowState, VaultListItemRowAction, VaultListItemRowEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: (any TimeProvider)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                VaultItemDecorativeImageView(
                    item: store.state.item,
                    iconBaseURL: store.state.iconBaseURL,
                    showWebIcons: store.state.showWebIcons
                )
                .imageStyle(.rowIcon)
                .padding(.vertical, 19)

                HStack {
                    switch store.state.item.itemType {
                    case let .cipher(cipherItem, _):
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 8) {
                                Text(cipherItem.name)
                                    .styleGuide(.body)
                                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                                    .lineLimit(1)
                                    .accessibilityIdentifier("CipherNameLabel")

                                if cipherItem.organizationId != nil {
                                    Asset.Images.collections16.swiftUIImage
                                        .imageStyle(.accessoryIcon16(
                                            color: SharedAsset.Colors.textSecondary.swiftUIColor,
                                            scaleWithFont: true
                                        ))
                                        .accessibilityLabel(Localizations.shared)
                                        .accessibilityIdentifier("CipherInCollectionIcon")
                                }

                                if cipherItem.attachments > 0 {
                                    Asset.Images.paperclip16.swiftUIImage
                                        .imageStyle(.accessoryIcon16(
                                            color: SharedAsset.Colors.textSecondary.swiftUIColor,
                                            scaleWithFont: true
                                        ))
                                        .accessibilityLabel(Localizations.attachments)
                                        .accessibilityIdentifier("CipherWithAttachmentsIcon")
                                }
                            }

                            if store.state.item.shouldShowFido2CredentialRpId,
                               let fido2CredentialRpId = store.state.item.fido2CredentialRpId {
                                Text(fido2CredentialRpId)
                                    .styleGuide(.subheadline)
                                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                                    .lineLimit(1)
                                    .accessibilityIdentifier("CipherFido2CredentialRpIdLabel")
                            }

                            if let subTitle = store.state.item.subtitle, !subTitle.isEmpty {
                                Text(subTitle)
                                    .styleGuide(.subheadline)
                                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                                    .lineLimit(1)
                                    .accessibilityIdentifier("CipherSubTitleLabel")
                            }
                        }
                        .accessibilityElement(children: .combine)

                        Spacer()

                        if !store.state.isFromExtension, !cipherItem.isDecryptionFailure {
                            AsyncButton {
                                await store.perform(.morePressed)
                            } label: {
                                Asset.Images.ellipsisHorizontal24.swiftUIImage
                                    .imageStyle(.rowIcon)
                            }
                            .accessibilityLabel(Localizations.more)
                            .accessibilityIdentifier("CipherOptionsButton")
                        }

                    case let .group(group, count):
                        Text(group.name)
                            .styleGuide(.body)
                            .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                            .accessibilityIdentifier("GroupNameLabel")
                        Spacer()
                        Text("\(count)")
                            .styleGuide(.body)
                            .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                            .accessibilityIdentifier("GroupCountLabel")

                    case let .totp(name, model):
                        totpCodeRow(name, model)
                    }
                }
                .padding(.vertical, 9)
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 16)

            if store.state.hasDivider {
                Divider()
                    .padding(.leading, 22 + 16 + 16)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(store.state.item.vaultItemAccessibilityId)
    }

    // MARK: - Private Views

    /// The row showing the totp code.
    @ViewBuilder
    private func totpCodeRow(
        _ name: String,
        _ model: VaultListTOTP
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name)
                .styleGuide(.body)
                .lineLimit(1)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
            if let username = model.cipherListView.type.loginListView?.username {
                Text(username)
                    .styleGuide(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
            }
        }
        Spacer()
        if let timeProvider {
            TOTPCountdownTimerView(
                timeProvider: timeProvider,
                totpCode: model.totpCode,
                onExpiration: nil
            )
        }
        if !model.requiresMasterPassword {
            Text(model.totpCode.displayCode)
                .styleGuide(.bodyMonospaced, weight: .regular, monoSpacedDigit: true)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
            if store.state.showTotpCopyButton {
                Button {
                    store.send(.copyTOTPCode(model.totpCode.code))
                } label: {
                    Asset.Images.copy24.swiftUIImage
                }
                .foregroundColor(SharedAsset.Colors.iconPrimary.swiftUIColor)
                .accessibilityLabel(Localizations.copyTotp)
            }
        }
    }
}
