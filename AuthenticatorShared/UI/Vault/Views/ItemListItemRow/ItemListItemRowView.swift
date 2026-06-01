import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - ItemListItemRowView

/// A view that displays information about an `ItemListItem` as a row in a list.
struct ItemListItemRowView: View {
    // MARK: Properties

    /// The `Store` for this view.
    var store: Store<
        ItemListItemRowState,
        ItemListItemRowAction,
        ItemListItemRowEffect,
    >

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                decorativeImage(
                    store.state.item,
                    iconBaseURL: store.state.iconBaseURL,
                    showWebIcons: store.state.showWebIcons,
                )
                .frame(width: 22, height: 22)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                .padding(.vertical, 19)
                .accessibilityHidden(true)
                .accessibilityIdentifier("ItemImage")

                HStack {
                    if let currentCode = store.state.item.totpCodeModel {
                        totpCodeRow(
                            name: store.state.item.name,
                            accountName: store.state.item.accountName,
                            currentCode: currentCode,
                            nextCode: store.state.item.nextTotpCodeModel,
                        )
                    } else {
                        EmptyView()
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
    private func decorativeImage(_ item: ItemListItem, iconBaseURL: URL?, showWebIcons: Bool) -> some View {
        placeholderDecorativeImage(SharedAsset.Icons.globe24)
    }

    /// The placeholder image for the decorative image.
    private func placeholderDecorativeImage(_ icon: SharedImageAsset) -> some View {
        Image(decorative: icon)
            .resizable()
            .scaledToFit()
    }

    /// The row showing the totp code.
    @ViewBuilder
    private func totpCodeRow(
        name: String,
        accountName: String?,
        currentCode: TOTPCodeModel,
        nextCode: TOTPCodeModel?,
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let name = name.nilIfEmpty {
                Text(name)
                    .styleGuide(.headline)
                    .lineLimit(1)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("ItemNameLabel")
                if let accountName = accountName?.nilIfEmpty {
                    Text(accountName)
                        .styleGuide(.subheadline)
                        .lineLimit(1)
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                        .accessibilityIdentifier("ItemAccountNameLabel")
                }
            } else {
                if let accountName = accountName?.nilIfEmpty {
                    Text(accountName)
                        .styleGuide(.headline)
                        .lineLimit(1)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        .accessibilityIdentifier("ItemAccountNameLabel")
                }
            }
        }
        Spacer()
        TOTPCodeDisplay(
            currentCode: currentCode,
            nextCode: nextCode,
            showNextTOTPCode: store.state.showNextTOTPCode,
            timeProvider: timeProvider,
        )

    }
}

#if DEBUG
#Preview("With account name") {
    ItemListItemRowView(
        store: Store(
            processor: StateProcessor(
                state: ItemListItemRowState(
                    item: ItemListItem(
                        id: UUID().uuidString,
                        name: "Example",
                        accountName: "person@example.com",
                        itemType: .totp(
                            model: ItemListTotpItem(
                                itemView: AuthenticatorItemView.fixture(),
                                totpCode: TOTPCodeModel(
                                    code: "123456",
                                    codeGenerationDate: Date(),
                                    period: 30,
                                ),
                            ),
                        ),
                    ),
                    hasDivider: true,
                    showNextTOTPCode: true,
                    showWebIcons: true,
                ),
            ),
        ),
        timeProvider: PreviewTimeProvider(),
    )
}

#Preview("Without account name") {
    ItemListItemRowView(
        store: Store(
            processor: StateProcessor(
                state: ItemListItemRowState(
                    item: ItemListItem(
                        id: UUID().uuidString,
                        name: "Example",
                        accountName: nil,
                        itemType: .totp(
                            model: ItemListTotpItem(
                                itemView: AuthenticatorItemView.fixture(),
                                totpCode: TOTPCodeModel(
                                    code: "123456",
                                    codeGenerationDate: Date(),
                                    period: 30,
                                ),
                            ),
                        ),
                    ),
                    hasDivider: true,
                    showNextTOTPCode: true,
                    showWebIcons: true,
                ),
            ),
        ),
        timeProvider: PreviewTimeProvider(),
    )
}

#Preview("With just account name") {
    ItemListItemRowView(
        store: Store(
            processor: StateProcessor(
                state: ItemListItemRowState(
                    item: ItemListItem(
                        id: UUID().uuidString,
                        name: "",
                        accountName: "person@example.com",
                        itemType: .totp(
                            model: ItemListTotpItem(
                                itemView: AuthenticatorItemView.fixture(),
                                totpCode: TOTPCodeModel(
                                    code: "123456",
                                    codeGenerationDate: Date(),
                                    period: 30,
                                ),
                            ),
                        ),
                    ),
                    hasDivider: true,
                    showNextTOTPCode: true,
                    showWebIcons: true,
                ),
            ),
        ),
        timeProvider: PreviewTimeProvider(),
    )
}

#Preview("With next code visible") {
    ItemListItemRowView(
        store: Store(
            processor: StateProcessor(
                state: ItemListItemRowState(
                    item: ItemListItem(
                        id: UUID().uuidString,
                        name: "Example",
                        accountName: "person@example.com",
                        itemType: .totp(
                            model: ItemListTotpItem(
                                itemView: AuthenticatorItemView.fixture(),
                                nextTotpCode: TOTPCodeModel(
                                    code: "789012",
                                    codeGenerationDate: Date(),
                                    period: 30,
                                ),
                                totpCode: TOTPCodeModel(
                                    code: "123456",
                                    codeGenerationDate: Date().addingTimeInterval(-22),
                                    period: 30,
                                ),
                            ),
                        ),
                    ),
                    hasDivider: true,
                    showNextTOTPCode: true,
                    showWebIcons: true,
                ),
            ),
        ),
        timeProvider: PreviewTimeProvider(
            fixedDate: Date(year: 2023, month: 12, day: 31, hour: 0, minute: 0, second: 25),
        ),
    )
}

#Preview("Digits without account") {
    NavigationView {
        VStack(spacing: 4) {
            ForEach(ItemListSection.digitsFixture(accountNames: false).items) { item in
                ItemListItemRowView(
                    store: Store(
                        processor: StateProcessor(
                            state: ItemListItemRowState(
                                item: item,
                                hasDivider: true,
                                showNextTOTPCode: true,
                                showWebIcons: true,
                            ),
                        ),
                    ),
                    timeProvider: PreviewTimeProvider(),
                )
            }
        }
    }
}

#Preview("Digits with account") {
    NavigationView {
        VStack(spacing: 4) {
            ForEach(ItemListSection.digitsFixture(accountNames: true).items) { item in
                ItemListItemRowView(
                    store: Store(
                        processor: StateProcessor(
                            state: ItemListItemRowState(
                                item: item,
                                hasDivider: true,
                                showNextTOTPCode: true,
                                showWebIcons: true,
                            ),
                        ),
                    ),
                    timeProvider: PreviewTimeProvider(),
                )
            }
        }
    }
}
#endif
