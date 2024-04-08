import SwiftUI

// MARK: - ProfileSwitcherToolbarView

/// A view that allows the user to view, select, and add profiles.
///
struct ProfileSwitcherToolbarView: View {
    /// The `Store` for this view.
    @ObservedObject var store: Store<ProfileSwitcherState, ProfileSwitcherAction, ProfileSwitcherEffect>

    var body: some View {
        profileSwitcherToolbarItem
    }

    /// The Toolbar item for the profile switcher view
    @ViewBuilder var profileSwitcherToolbarItem: some View {
        Button {
            store.send(.requestedProfileSwitcher(visible: !store.state.isVisible))
        } label: {
            HStack {
                profileSwitcherIcon(
                    color: store.state.showPlaceholderToolbarIcon
                        ? nil : store.state.activeAccountProfile?.color,
                    initials: store.state.showPlaceholderToolbarIcon
                        ? nil : store.state.activeAccountProfile?.userInitials,
                    textColor: store.state.showPlaceholderToolbarIcon
                        ? nil : store.state.activeAccountProfile?.profileIconTextColor
                )
                Spacer()
            }
            .frame(minWidth: 50)
        }
        .accessibilityIdentifier("CurrentActiveAccount")
        .accessibilityLabel(Localizations.account)
        .hidden(!store.state.showPlaceholderToolbarIcon && store.state.accounts.isEmpty)
    }
}

extension View {
    /// An icon for a profile switcher item.
    ///
    /// - Parameters:
    ///   - color: The color of the icon.
    ///   - initials: The initials for the icon.
    ///   - textColor: The text color for the icon.
    ///
    @ViewBuilder
    func profileSwitcherIcon(
        color: Color?,
        initials: String?,
        textColor: Color?
    ) -> some View {
        Text(initials ?? "  ")
            .styleGuide(.caption2Monospaced)
            .padding(4)
            .frame(minWidth: 22, alignment: .center)
            .background {
                if initials == nil {
                    Asset.Images.horizontalDots.swiftUIImage
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .opacity(initials == nil ? 1.0 : 0.0)
                        .accessibilityHidden(initials != nil)
                }
            }
            .foregroundColor(textColor ?? Asset.Colors.primaryBitwarden.swiftUIColor)
            .background(color ?? Asset.Colors.primaryBitwarden.swiftUIColor.opacity(0.12))
            .clipShape(Circle())
    }
}

// MARK: Previews

#if DEBUG
extension ProfileSwitcherItem {
    static let previewSelectedAccount = ProfileSwitcherItem(
        color: .purple,
        email: "anne.account@bitwarden.com",
        isUnlocked: true,
        userId: "1",
        userInitials: "AA",
        webVault: ""
    )
}

#Preview {
    NavigationView {
        Spacer()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ProfileSwitcherToolbarView(
                        store: Store(
                            processor: StateProcessor(
                                state: .empty()
                            )
                        )
                    )
                }
            }
    }
    .previewDisplayName("Empty")
}

#Preview {
    NavigationView {
        Spacer()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ProfileSwitcherToolbarView(
                        store: Store(
                            processor: StateProcessor(
                                state: .init(
                                    accounts: [.previewSelectedAccount],
                                    activeAccountId: nil,
                                    allowLockAndLogout: true,
                                    isVisible: false
                                )
                            )
                        )
                    )
                }
            }
    }
    .previewDisplayName("No Active")
}

#Preview {
    NavigationView {
        Spacer()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ProfileSwitcherToolbarView(
                        store: Store(
                            processor: StateProcessor(
                                state: ProfileSwitcherState(
                                    accounts: [
                                        .previewSelectedAccount,
                                    ],
                                    activeAccountId: ProfileSwitcherItem.previewSelectedAccount.userId,
                                    allowLockAndLogout: true,
                                    isVisible: false
                                )
                            )
                        )
                    )
                }
            }
    }
    .previewDisplayName("Single Account")
}

#Preview {
    NavigationView {
        Spacer()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ProfileSwitcherToolbarView(
                        store: Store(
                            processor: StateProcessor(
                                state: ProfileSwitcherState(
                                    accounts: [
                                        .previewSelectedAccount,
                                        ProfileSwitcherItem(
                                            color: .green,
                                            email: "bonus.bridge@bitwarde.com",
                                            isUnlocked: true,
                                            userId: "123",
                                            userInitials: "BB",
                                            webVault: ""
                                        ),
                                    ],
                                    activeAccountId: "123",
                                    allowLockAndLogout: true,
                                    isVisible: false
                                )
                            )
                        )
                    )
                }
            }
    }
    .previewDisplayName("Dual Account")
}
#endif
