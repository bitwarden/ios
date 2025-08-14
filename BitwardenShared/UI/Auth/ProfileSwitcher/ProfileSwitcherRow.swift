import BitwardenResources
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
                        VStack(alignment: .leading, spacing: -4) {
                            Text(title)
                                .styleGuide(.body)
                                .accessibilityIdentifier("AccountEmailLabel")
                                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                            if let hostSubtitle {
                                Text(hostSubtitle)
                                    .styleGuide(.subheadline)
                                    .accessibilityIdentifier("AccountHostUrlLabel")
                                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                            }
                            if let statusSubtitle {
                                Text(statusSubtitle)
                                    .styleGuide(.subheadline, isItalic: true)
                                    .accessibilityIdentifier("AccountStatusLabel")
                                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                            }
                        }
                        .lineLimit(1)
                        .truncationMode(.tail)
                        Spacer()
                        trailingIcon?
                            .imageStyle(.rowIcon(color: trailingIconColor))
                            .accessibilityIdentifier(store.state.trailingIconAccessibilityID)
                    }
                    .padding([.top, .bottom], (statusSubtitle != nil || hostSubtitle != nil) ? 9 : 19)
                    .padding([.trailing], 16)
                    divider
                }
                .padding([.leading], 4)
            }
            .padding([.leading], 16)
        }
        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
    }

    /// A row divider view
    @ViewBuilder private var divider: some View {
        if store.state.showDivider {
            Rectangle()
                .frame(height: 1.0)
                .frame(maxWidth: .infinity)
                .foregroundColor(SharedAsset.Colors.strokeDivider.swiftUIColor)
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
            Asset.Images.plus16.swiftUIImage
                .imageStyle(.accessoryIcon16(color: SharedAsset.Colors.iconSecondary.swiftUIColor))
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

    /// A subtitle for the row, used to indicate vault host
    private var hostSubtitle: String? {
        switch store.state.rowType {
        case let .active(account),
             let .alternate(account):
            return account.webVault
        case .addAccount:
            return nil
        }
    }

    /// A subtitle for the row, used to indicate lock status
    private var statusSubtitle: String? {
        switch store.state.rowType {
        case .active,
             .addAccount:
            return nil
        case let .alternate(account):
            return switch (account.isUnlocked, account.isLoggedOut) {
            case (true, false):
                Localizations.accountUnlocked.lowercased()
            case (false, false):
                Localizations.accountLocked.lowercased()
            case (_, true):
                Localizations.accountLoggedOut.lowercased()
            }
        }
    }

    /// A trailing icon for the row
    private var trailingIcon: Image? {
        switch store.state.rowType {
        case .active:
            return Asset.Images.checkCircle24.swiftUIImage
        case let .alternate(account):
            if account.isUnlocked {
                return Asset.Images.unlocked24.swiftUIImage
            } else {
                return Asset.Images.locked24.swiftUIImage
            }
        case .addAccount:
            return nil
        }
    }

    /// A trailing icon color for the row
    private var trailingIconColor: Color {
        switch store.state.rowType {
        case .active:
            SharedAsset.Colors.iconPrimary.swiftUIColor
        case .alternate:
            SharedAsset.Colors.textSecondary.swiftUIColor
        case .addAccount:
            SharedAsset.Colors.backgroundSecondary.swiftUIColor
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
        .accessibilityAction {
            Task {
                await store.perform(.accessibility(.select(profileSwitcherItem)))
            }
        }
        .conditionalAccessibilityAsyncAction(
            if: store.state.allowLockAndLogout && profileSwitcherItem.canBeLocked
                && profileSwitcherItem.isUnlocked,
            named: Localizations.lock
        ) {
            await store.perform(.accessibility(.lock(profileSwitcherItem)))
        }
        .conditionalAccessibilityAction(
            if: store.state.allowLockAndLogout && !profileSwitcherItem.isLoggedOut,
            named: Localizations.logOut
        ) {
            store.send(.accessibility(.logout(profileSwitcherItem)))
        }
        .conditionalAccessibilityAction(
            if: store.state.allowLockAndLogout && profileSwitcherItem.isLoggedOut,
            named: Localizations.remove
        ) {
            store.send(.accessibility(.remove(profileSwitcherItem)))
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
#Preview("Active Unlocked Account") {
    NavigationView {
        ProfileSwitcherRow(
            store: Store(
                processor: StateProcessor(
                    state: ProfileSwitcherRowState(
                        shouldTakeAccessibilityFocus: true,
                        rowType: .active(.fixtureUnlocked)
                    )
                )
            )
        )
    }
}

#Preview("Active Locked Account") {
    NavigationView {
        ProfileSwitcherRow(
            store: Store(
                processor: StateProcessor(
                    state: ProfileSwitcherRowState(
                        shouldTakeAccessibilityFocus: true,
                        rowType: .active(.fixtureLocked)
                    )
                )
            )
        )
    }
}

#Preview("Active Account, No Divider") {
    NavigationView {
        ProfileSwitcherRow(
            store: Store(
                processor: StateProcessor(
                    state: ProfileSwitcherRowState(
                        shouldTakeAccessibilityFocus: true,
                        showDivider: false,
                        rowType: .active(.fixtureLocked)
                    )
                )
            )
        )
    }
}

#Preview("Alternate Unlocked Account") {
    NavigationView {
        ProfileSwitcherRow(
            store: Store(
                processor: StateProcessor(
                    state: ProfileSwitcherRowState(
                        shouldTakeAccessibilityFocus: true,
                        rowType: .alternate(.fixtureUnlocked)
                    )
                )
            )
        )
    }
}

#Preview("Alternate Locked Account") {
    NavigationView {
        ProfileSwitcherRow(
            store: Store(
                processor: StateProcessor(
                    state: ProfileSwitcherRowState(
                        shouldTakeAccessibilityFocus: true,
                        rowType: .alternate(.fixtureLocked)
                    )
                )
            )
        )
    }
}

#Preview("Alternate Logged Out Account") {
    NavigationView {
        ProfileSwitcherRow(
            store: Store(
                processor: StateProcessor(
                    state: ProfileSwitcherRowState(
                        shouldTakeAccessibilityFocus: true,
                        rowType: .alternate(.fixtureLoggedOut)
                    )
                )
            )
        )
    }
}

#Preview("Add Account") {
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
}
#endif
