import SwiftUI

// MARK: - ProfileSwitcherRow

/// A row view that allows the user to view, select, or add profiles.
///
struct ProfileSwitcherRow: View {
    // MARK: Properties

    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceoverEnabled: Bool

    /// The `Store` for this view.
    @ObservedObject var store: Store<ProfileSwitcherRowState, ProfileSwitcherRowAction, ProfileSwitcherRowEffect>

    /// Defines the accessibility focus state
    @AccessibilityFocusState var isFocused: Bool

    var body: some View {
        button
            .onChange(of: store.state.shouldTakeAccessibilityFocus) { shouldTakeFocus in
                updateFocusIfNeeded(shouldTakeFocus: shouldTakeFocus)
            }
            .accessibilityIdentifier("AccountCell")
    }

    // MARK: Private Properties

    /// A button with  accessibility traits for active accounts
    @ViewBuilder private var button: some View {
        switch store.state.rowType {
        case .addAccount:
            AsyncButton {
                await store.perform(.pressed(rowType))
            } label: {
                rowContents
            }
            .accessibilityAsyncAction(named: Localizations.addAccount) {
                await store.perform(.pressed(rowType))
            }
        case let .alternate(account):
            accountRow(for: account, isSelected: false)
        case let .active(account):
            accountRow(for: account, isSelected: true)
        }
    }

    /// The row contents
    private var rowContents: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            HStack(spacing: 0) {
                leadingIcon
                    .padding(.trailing, 16)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(title)
                                .styleGuide(.body)
                                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                                .truncationMode(.tail)
                                .lineLimit(1)
                            if let subtitle {
                                Text(subtitle)
                                    .styleGuide(.subheadline)
                                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                    .accessibilityIdentifier("AccountStatusLabel")
                            }
                        }
                        Spacer()
                        trailingIcon?
                            .resizable()
                            .frame(width: 22, height: 22)
                            .foregroundColor(trailingIconColor)
                            .accessibilityIdentifier(store.state.trailingIconAccessibilityID)
                    }
                    .padding([.top, .bottom], subtitle != nil ? 9 : 19)
                    .padding([.trailing], 16)
                    divider
                }
                .padding([.leading], 4)
            }
            .padding([.leading], 16)
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
    }

    /// A row divider view
    @ViewBuilder private var divider: some View {
        if store.state.showDivider {
            Rectangle()
                .frame(height: 1.0)
                .frame(maxWidth: .infinity)
                .foregroundColor(Asset.Colors.separatorOpaque.swiftUIColor)
        } else {
            EmptyView()
        }
    }

    /// A leading icon for the row
    @ViewBuilder private var leadingIcon: some View {
        switch store.state.rowType {
        case let .active(account),
             let .alternate(account):
            profileSwitcherIcon(
                color: account.color,
                initials: account.userInitials,
                textColor: account.profileIconTextColor
            )
            .accessibilityLabel(Localizations.account)
        case .addAccount:
            Asset.Images.plus.swiftUIImage
                .resizable()
                .frame(width: 19, height: 19)
                .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                .padding(4)
        }
    }

    /// The type of the row
    private var rowType: ProfileSwitcherRowState.RowType {
        store.state.rowType
    }

    /// A title for the row
    private var title: String {
        switch store.state.rowType {
        case let .active(account),
             let .alternate(account):
            return account.email
        case .addAccount:
            return Localizations.addAccount
        }
    }

    /// A title for the row
    private var subtitle: String? {
        switch store.state.rowType {
        case .active,
             .addAccount:
            return nil
        case let .alternate(account):
            return account.isUnlocked
                ? Localizations.accountUnlocked.lowercased()
                : Localizations.accountLocked.lowercased()
        }
    }

    /// A trailing icon for the row
    private var trailingIcon: Image? {
        switch store.state.rowType {
        case .active:
            return Asset.Images.roundCheck.swiftUIImage
        case let .alternate(account):
            if account.isUnlocked {
                return Asset.Images.unlocked.swiftUIImage
            } else {
                return Asset.Images.locked.swiftUIImage
            }
        case .addAccount:
            return nil
        }
    }

    /// A trailing icon color for the row
    private var trailingIconColor: Color {
        switch store.state.rowType {
        case .active:
            Asset.Colors.primaryBitwarden.swiftUIColor
        case .alternate:
            Asset.Colors.textSecondary.swiftUIColor
        case .addAccount:
            Asset.Colors.backgroundPrimary.swiftUIColor
        }
    }

    /// Builds an account row for a given row type
    ///
    /// - Parameters
    ///     - profileSwitcherItem: The item used to construct the account row.
    ///     - isSelected: Is this item selected?
    ///
    @ViewBuilder
    private func accountRow(
        for profileSwitcherItem: ProfileSwitcherItem,
        isSelected: Bool
    ) -> some View {
        AsyncButton {} label: {
            rowContents
                .onTapGesture {
                    await store.perform(
                        .pressed(
                            isSelected
                                ? .active(profileSwitcherItem)
                                : .alternate(profileSwitcherItem)
                        )
                    )
                }
                .onLongPressGesture(if: store.state.allowLockAndLogout) {
                    await store.perform(
                        .longPressed(
                            isSelected
                                ? .active(profileSwitcherItem)
                                : .alternate(profileSwitcherItem)
                        )
                    )
                }
        }
        .accessibilityAsyncAction(named: Localizations.select) {
            await store.perform(.accessibility(.select(profileSwitcherItem)))
        }
        .conditionalAccessibilityAsyncAction(
            if: store.state.allowLockAndLogout,
            named: Localizations.lock
        ) {
            await store.perform(.accessibility(.lock(profileSwitcherItem)))
        }
        .conditionalAccessibilityAction(
            if: store.state.allowLockAndLogout,
            named: Localizations.logOut
        ) {
            store.send(.accessibility(.logout(profileSwitcherItem)))
        }
        .accessibility(
            if: isSelected,
            addTraits: .isSelected
        )
    }

    /// Helper function to set accessibility focus state inside the view body
    private func updateFocusIfNeeded(shouldTakeFocus: Bool) {
        if shouldTakeFocus,
           isVoiceoverEnabled {
            isFocused = true
        }
    }
}

#if DEBUG
extension ProfileSwitcherItem {
    static var unlockedAccountPreview = ProfileSwitcherItem(
        color: .purple,
        email: "anne.account@bitwarden.com",
        isUnlocked: true,
        userId: "1",
        userInitials: "AA",
        webVault: ""
    )

    static var lockedAccountPreview = ProfileSwitcherItem(
        color: .purple,
        email: "anne.account@bitwarden.com",
        isUnlocked: false,
        userId: "2",
        userInitials: "AA",
        webVault: ""
    )
}

#Preview {
    NavigationView {
        ProfileSwitcherRow(
            store: Store(
                processor: StateProcessor(
                    state: ProfileSwitcherRowState(
                        shouldTakeAccessibilityFocus: true,
                        rowType: .active(.unlockedAccountPreview)
                    )
                )
            )
        )
    }
    .previewDisplayName("Active Unlocked Account")
}

#Preview {
    NavigationView {
        ProfileSwitcherRow(
            store: Store(
                processor: StateProcessor(
                    state: ProfileSwitcherRowState(
                        shouldTakeAccessibilityFocus: true,
                        rowType: .active(.lockedAccountPreview)
                    )
                )
            )
        )
    }
    .previewDisplayName("Active Locked Account")
}

#Preview {
    NavigationView {
        ProfileSwitcherRow(
            store: Store(
                processor: StateProcessor(
                    state: ProfileSwitcherRowState(
                        shouldTakeAccessibilityFocus: true,
                        showDivider: false,
                        rowType: .active(.lockedAccountPreview)
                    )
                )
            )
        )
    }
    .previewDisplayName("Active Account, No Divider")
}

#Preview {
    NavigationView {
        ProfileSwitcherRow(
            store: Store(
                processor: StateProcessor(
                    state: ProfileSwitcherRowState(
                        shouldTakeAccessibilityFocus: true,
                        rowType: .alternate(.unlockedAccountPreview)
                    )
                )
            )
        )
    }
    .previewDisplayName("Alternate Unlocked Account")
}

#Preview {
    NavigationView {
        ProfileSwitcherRow(
            store: Store(
                processor: StateProcessor(
                    state: ProfileSwitcherRowState(
                        shouldTakeAccessibilityFocus: true,
                        rowType: .alternate(.lockedAccountPreview)
                    )
                )
            )
        )
    }
    .previewDisplayName("Alternate Locked Account")
}

#Preview {
    NavigationView {
        ProfileSwitcherRow(
            store: Store(
                processor: StateProcessor(
                    state: ProfileSwitcherRowState(
                        shouldTakeAccessibilityFocus: false,
                        rowType: .addAccount
                    )
                )
            )
        )
    }
    .previewDisplayName("Add Account")
}
#endif
