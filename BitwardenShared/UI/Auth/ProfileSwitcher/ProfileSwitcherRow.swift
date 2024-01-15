import SwiftUI

// MARK: - ProfileSwitcherRow

/// A row view that allows the user to view, select, or add profiles.
///
struct ProfileSwitcherRow: View {
    // MARK: Properties

    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceoverEnabled: Bool

    /// The `Store` for this view.
    @ObservedObject var store: Store<ProfileSwitcherRowState, ProfileSwitcherRowAction, Void>

    /// Defines the accessibility focus state
    @AccessibilityFocusState var isFocused: Bool

    var body: some View {
        button
            .onChange(of: store.state.shouldTakeAccessibilityFocus) { shouldTakeFocus in
                updateFocusIfNeeded(shouldTakeFocus: shouldTakeFocus)
            }
    }

    // MARK: Private Properties

    /// A button with  accessibility traits for active accounts
    @ViewBuilder private var button: some View {
        switch store.state.rowType {
        case .addAccount,
             .alternate:
            Button {
                store.send(.pressed(rowType))
            } label: {
                rowContents
            }
        case .active:
            Button {
                store.send(.pressed(rowType))
            } label: {
                rowContents
            }
            .accessibility(
                addTraits: .isSelected
            )
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
                            }
                        }
                        Spacer()
                        trailingIcon?
                            .resizable()
                            .frame(width: 22, height: 22)
                            .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
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
            Text(account.userInitials)
                .styleGuide(.caption2Monospaced)
                .foregroundColor(.white)
                .padding(4)
                .background(account.color)
                .clipShape(Circle())
                .frame(minWidth: 22)
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

    /// Helper function to set accessibility focus state inside the view body
    private func updateFocusIfNeeded(shouldTakeFocus: Bool) {
        if shouldTakeFocus,
           isVoiceoverEnabled {
            isFocused = true
        }
    }
}

#if DEBUG
struct ProfileSwitcherRow_Previews: PreviewProvider {
    static var unlockedAccount = ProfileSwitcherItem(
        color: .purple,
        email: "anne.account@bitwarden.com",
        isUnlocked: true,
        userInitials: "AA"
    )

    static var lockedAccount = ProfileSwitcherItem(
        color: .purple,
        email: "anne.account@bitwarden.com",
        isUnlocked: false,
        userInitials: "AA"
    )

    static var previews: some View {
        NavigationView {
            ProfileSwitcherRow(
                store: Store(
                    processor: StateProcessor(
                        state: ProfileSwitcherRowState(
                            shouldTakeAccessibilityFocus: true,
                            rowType: .active(unlockedAccount)
                        )
                    )
                )
            )
        }
        .previewDisplayName("Active Unlocked Account")

        NavigationView {
            ProfileSwitcherRow(
                store: Store(
                    processor: StateProcessor(
                        state: ProfileSwitcherRowState(
                            shouldTakeAccessibilityFocus: true,
                            rowType: .active(lockedAccount)
                        )
                    )
                )
            )
        }
        .previewDisplayName("Active Locked Account")

        NavigationView {
            ProfileSwitcherRow(
                store: Store(
                    processor: StateProcessor(
                        state: ProfileSwitcherRowState(
                            shouldTakeAccessibilityFocus: true,
                            showDivider: false,
                            rowType: .active(lockedAccount)
                        )
                    )
                )
            )
        }
        .previewDisplayName("Active Account, No Divider")

        NavigationView {
            ProfileSwitcherRow(
                store: Store(
                    processor: StateProcessor(
                        state: ProfileSwitcherRowState(
                            shouldTakeAccessibilityFocus: true,
                            rowType: .alternate(unlockedAccount)
                        )
                    )
                )
            )
        }
        .previewDisplayName("Alternate Unlocked Account")

        NavigationView {
            ProfileSwitcherRow(
                store: Store(
                    processor: StateProcessor(
                        state: ProfileSwitcherRowState(
                            shouldTakeAccessibilityFocus: true,
                            rowType: .alternate(lockedAccount)
                        )
                    )
                )
            )
        }
        .previewDisplayName("Alternate Locked Account")

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
}
#endif
