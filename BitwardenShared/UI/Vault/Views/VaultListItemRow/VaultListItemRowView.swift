import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - View+MoreOptionsAccessibilityActions

private extension View {
    /// Adds a named `.accessibilityAction` for each of the provided more-options action kinds.
    /// The number of kinds is data-driven (it depends on the cipher's `copyableFields`), so this
    /// folds over the list at runtime rather than statically chaining a fixed set of conditional
    /// modifiers; `AnyView` erasure is used so the accumulator type stays fixed across the fold.
    ///
    /// - Parameters:
    ///   - kinds: The more-options action kinds to expose as accessibility actions.
    ///   - onSelect: Called with the selected kind when its accessibility action is activated.
    ///
    func accessibilityMoreOptionsActions(
        _ kinds: [MoreOptionsActionKind],
        onSelect: @escaping (MoreOptionsActionKind) async -> Void,
    ) -> AnyView {
        kinds.reduce(AnyView(self)) { view, kind in
            AnyView(
                view.accessibilityAsyncAction(named: kind.localizedName) {
                    await onSelect(kind)
                },
            )
        }
    }
}

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
                AsyncButton {
                    await store.perform(.pressed)
                } label: {
                    HStack(spacing: 16) {
                        VaultItemDecorativeImageView(
                            item: store.state.item,
                            iconBaseURL: store.state.iconBaseURL,
                            showWebIcons: store.state.showWebIcons,
                        )
                        .imageStyle(.rowIcon)
                        .padding(.vertical, 19)

                        HStack {
                            switch store.state.item.itemType {
                            case let .cipher(cipherItem, _):
                                cipherRowLabel(cipherItem)
                            case let .group(group, count):
                                groupRowLabel(group, count)
                            case let .totp(name, model):
                                totpRowLabel(name, model)
                            }
                        }
                        .padding(.vertical, 9)
                    }
                }
                .accessibilityIdentifier("VaultListItemRowButton")

                if case let .cipher(cipherItem, _) = store.state.item.itemType,
                   !store.state.isFromExtension, !cipherItem.isDecryptionFailure {
                    AsyncButton {
                        await store.perform(.morePressed)
                    } label: {
                        SharedAsset.Icons.ellipsisHorizontal24.swiftUIImage
                            .imageStyle(.rowIcon)
                    }
                    .accessibilityLabel(Localizations.moreOptions)
                    .accessibilityIdentifier("CipherOptionsButton")
                }

                if case let .totp(_, model) = store.state.item.itemType,
                   !model.requiresMasterPassword, store.state.showTotpCopyButton {
                    Button {
                        store.send(.copyTOTPCode(model.totpCode.code))
                    } label: {
                        SharedAsset.Icons.copy24.swiftUIImage
                    }
                    .foregroundColor(SharedAsset.Colors.iconPrimary.swiftUIColor)
                    .accessibilityLabel(Localizations.copyTotp)
                }
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
        .accessibilityAction {
            Task { await store.perform(.pressed) }
        }
        .accessibilityMoreOptionsActions(accessibilityMoreOptionsActionKinds) { kind in
            await store.perform(.accessibilityMoreOptionsActionPressed(kind))
        }
        .conditionalAccessibilityAction(
            if: {
                if case let .totp(_, model) = store.state.item.itemType {
                    !model.requiresMasterPassword && store.state.showTotpCopyButton
                } else {
                    false
                }
            }(),
            named: Localizations.copyTotp,
        ) {
            if case let .totp(_, model) = store.state.item.itemType {
                store.send(.copyTOTPCode(model.totpCode.code))
            }
        }
    }

    /// The more-options accessibility action kinds applicable to this row, empty for non-cipher
    /// items, decryption-failure ciphers, or when running in an extension (matching the ellipsis
    /// button's own visibility gate).
    private var accessibilityMoreOptionsActionKinds: [MoreOptionsActionKind] {
        guard case let .cipher(cipherItem, _) = store.state.item.itemType,
              !store.state.isFromExtension, !cipherItem.isDecryptionFailure else {
            return []
        }
        return cipherItem.applicableMoreOptionsActionKinds(hasPremium: store.state.hasPremium)
    }

    // MARK: - Private Views

    /// The label content for a cipher row, excluding the more-options button.
    @ViewBuilder
    private func cipherRowLabel(_ cipherItem: CipherListView) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(cipherItem.name)
                    .styleGuide(.body)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .lineLimit(1)
                    .accessibilityIdentifier("CipherNameLabel")

                if cipherItem.organizationId != nil {
                    (store.state.isVfo1FoundationFeatureFlagEnabled
                        ? SharedAsset.Icons.sharedFolder16
                        : SharedAsset.Icons.collections16).swiftUIImage
                        .imageStyle(.accessoryIcon16(
                            color: SharedAsset.Colors.textSecondary.swiftUIColor,
                            scaleWithFont: true,
                        ))
                        .accessibilityLabel(Localizations.shared)
                        .accessibilityIdentifier("CipherInCollectionIcon")
                }

                if cipherItem.attachments > 0 {
                    SharedAsset.Icons.paperclip16.swiftUIImage
                        .imageStyle(.accessoryIcon16(
                            color: SharedAsset.Colors.textSecondary.swiftUIColor,
                            scaleWithFont: true,
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
    }

    /// The label content for a group row.
    @ViewBuilder
    private func groupRowLabel(_ group: VaultListGroup, _ count: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(group.name)
                .styleGuide(.body)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                .accessibilityIdentifier("GroupNameLabel")

            if let subTitle = store.state.item.subtitle, !subTitle.isEmpty {
                Text(subTitle)
                    .styleGuide(.subheadline)
                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .lineLimit(1)
                    .accessibilityIdentifier("GroupSubTitleLabel")
            }
        }
        .accessibilityElement(children: .combine)

        Spacer()

        if let accessoryIcon = store.state.item.accessoryIcon {
            Image(decorative: accessoryIcon)
                .imageStyle(.rowIcon)
                .accessibilityHidden(true)
        } else {
            Text("\(count)")
                .styleGuide(.body)
                .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                .accessibilityIdentifier("GroupCountLabel")
        }
    }

    /// The label content for a row showing the totp code, excluding the copy button.
    @ViewBuilder
    private func totpRowLabel(
        _ name: String,
        _ model: VaultListTOTP,
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
                onExpiration: nil,
            )
        }
        if !model.requiresMasterPassword {
            Text(model.totpCode.displayCode)
                .styleGuide(.bodyMonospaced, weight: .regular, monoSpacedDigit: true)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
        }
    }
}
