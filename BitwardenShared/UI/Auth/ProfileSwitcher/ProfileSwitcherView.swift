import SwiftUI

// MARK: - ProfileSwitcherView

/// A view that allows the user to view, select, and add profiles.
///
struct ProfileSwitcherView: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceoverEnabled: Bool

    /// Defines the accessibility focus state
    @AccessibilityFocusState var isCurrentAccountFocused: Bool

    /// The `Store` for this view.
    @ObservedObject var store: Store<ProfileSwitcherState, ProfileSwitcherAction, Void>

    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundView
            ScrollView {
                LazyVStack(spacing: 0.0) {
                    accounts
                    addAccountRow
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        }
        .onAppear {
            guard store.state.isVisible,
                  isVoiceoverEnabled else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isCurrentAccountFocused = true
            }
        }
    }

    // MARK: Private Properties

    /// A row to add an account
    @ViewBuilder private var addAccountRow: some View {
        Button {
            store.send(.addAccountPressed)
        } label: {
            profileSwitcherRowView(
                leadingIcon: {
                    Asset.Images.plus.swiftUIImage
                        .resizable()
                        .frame(width: 19, height: 19)
                        .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                        .padding(4)
                },
                shouldShowDivider: false,
                title: Localizations.addAccount
            )
        }
    }

    /// A background view with accessibility enabled
    private var backgroundView: some View {
        Color.black.opacity(0.4)
            .onTapGesture {
                store.send(.backgroundPressed)
            }
            .accessibilityAction {
                store.send(.backgroundPressed)
            }
            .accessibilityLabel(Localizations.close)
            .ignoresSafeArea()
    }

    /// A group of account views
    private var accounts: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(store.state.alternateAccounts.indices, id: \.self) { index in
                let account = store.state.alternateAccounts[index]
                unselectedProfileSwitcherRow(accountProfile: account)
            }
            selectedProfileSwitcherRow(accountProfile: store.state.currentAccountProfile)
        }
    }

    // MARK: Private functions

    /// A generic row styled for the profile switcher
    @ViewBuilder
    private func profileSwitcherRowView(
        leadingIcon: () -> some View,
        shouldShowDivider: Bool = true,
        subtitle: String? = nil,
        title: String,
        trailingIcon: Image? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 0.0) {
            HStack(spacing: 0) {
                leadingIcon()
                    .padding(.trailing, 16)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(title)
                                .font(.styleGuide(.body))
                                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                            if let subtitle {
                                Text(subtitle)
                                    .font(.styleGuide(.subheadline))
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
                    if shouldShowDivider {
                        Rectangle()
                            .frame(height: 1.0)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Asset.Colors.separatorOpaque.swiftUIColor)
                    }
                }
                .padding([.leading], 4)
            }
            .padding([.leading], 16)
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
    }

    /// A row to display the active account profile
    ///
    /// - Parameter accountProfile: A `ProfileSwitcherItem` to display in row format
    ///
    @ViewBuilder
    private func selectedProfileSwitcherRow(
        accountProfile: ProfileSwitcherItem
    ) -> some View {
        Button {
            store.send(.accountPressed(accountProfile))
        } label: {
            profileSwitcherRowView(
                leadingIcon: {
                    Text(accountProfile.userInitials)
                        .font(.styleGuide(.caption2Monospaced))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(accountProfile.color)
                        .clipShape(Circle())
                        .frame(minWidth: 22)
                        .accessibilityLabel(Localizations.account)
                },
                subtitle: nil,
                title: accountProfile.email,
                trailingIcon: Asset.Images.roundCheck.swiftUIImage
            )
        }
        .accessibility(addTraits: .isSelected)
        .accessibilityFocused($isCurrentAccountFocused)
    }

    /// A row to display an alternate account profile
    ///
    /// - Parameter accountProfile: A `ProfileSwitcherItem` to display in row format
    ///
    @ViewBuilder
    private func unselectedProfileSwitcherRow(
        accountProfile: ProfileSwitcherItem
    ) -> some View {
        Button {
            store.send(.accountPressed(accountProfile))
        } label: {
            profileSwitcherRowView(
                leadingIcon: {
                    Text(accountProfile.userInitials)
                        .font(.styleGuide(.caption2Monospaced))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(accountProfile.color)
                        .clipShape(Circle())
                        .frame(minWidth: 22)
                        .accessibilityLabel(Localizations.account)
                },
                subtitle: accountProfile.isUnlocked
                    ? Localizations.accountUnlocked.lowercased()
                    : Localizations.accountLocked.lowercased(),
                title: accountProfile.email,
                trailingIcon: accountProfile.isUnlocked
                    ? Asset.Images.unlocked.swiftUIImage
                    : Asset.Images.lockedOutline.swiftUIImage
            )
        }
    }
}

// MARK: Previews

struct ProfileSwitcherView_Previews: PreviewProvider {
    static var selectedAccount = ProfileSwitcherItem(
        color: .purple,
        email: "anne.account@bitwarden.com",
        isUnlocked: true,
        userInitials: "AA"
    )

    static var previews: some View {
        NavigationView {
            ProfileSwitcherView(
                store: Store(
                    processor: StateProcessor(
                        state: ProfileSwitcherState(
                            currentAccountProfile: selectedAccount,
                            isVisible: true
                        )
                    )
                )
            )
        }
        .previewDisplayName("Single Account")

        NavigationView {
            ProfileSwitcherView(
                store: Store(
                    processor: StateProcessor(
                        state: ProfileSwitcherState(
                            alternateAccounts: [
                                ProfileSwitcherItem(
                                    color: .green,
                                    email: "bonus.bridge@bitwarde.com",
                                    isUnlocked: true,
                                    userInitials: "BB"
                                ),
                            ],
                            currentAccountProfile: selectedAccount,
                            isVisible: true
                        )
                    )
                )
            )
        }
        .previewDisplayName("Dual Account")

        NavigationView {
            ProfileSwitcherView(
                store: Store(
                    processor: StateProcessor(
                        state: ProfileSwitcherState(
                            alternateAccounts: [
                                ProfileSwitcherItem(
                                    color: .yellow,
                                    email: "bonus.bridge@bitwarden.com",
                                    isUnlocked: true,
                                    userInitials: "BB"
                                ),
                                ProfileSwitcherItem(
                                    color: .teal,
                                    email: "concurrent.claim@bitarden.com",
                                    isUnlocked: true,
                                    userInitials: "CC"
                                ),
                                ProfileSwitcherItem(
                                    color: .indigo,
                                    email: "double.dip@bitwarde.com",
                                    isUnlocked: true,
                                    userInitials: "DD"
                                ),
                                ProfileSwitcherItem(
                                    color: .green,
                                    email: "extra.edition@bitwarden.com",
                                    isUnlocked: false,
                                    userInitials: "EE"
                                ),
                            ],
                            currentAccountProfile: ProfileSwitcherItem(
                                color: .purple,
                                email: "anne.account@bitwarden.com",
                                userInitials: "AA"
                            ),
                            isVisible: true
                        )
                    )
                )
            )
        }
        .previewDisplayName("Multi Account")
    }
}
