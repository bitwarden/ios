import SwiftUI

// MARK: - ProfileSwitcherToolbarView

/// A view that allows the user to view, select, and add profiles.
///
struct ProfileSwitcherToolbarView: View {
    /// The `Store` for this view.
    @ObservedObject var store: Store<ProfileSwitcherState, ProfileSwitcherAction, Void>

    var body: some View {
        profileSwitcherToolbarItem
    }

    /// The Toolbar item for the profile switcher view
    @ViewBuilder var profileSwitcherToolbarItem: some View {
        Button {
            store.send(.requestedProfileSwitcher(visible: !store.state.isVisible))
        } label: {
            if !store.state.accounts.isEmpty {
                HStack {
                    Text(store.state.activeAccountInitials)
                        .styleGuide(.caption2Monospaced)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(
                            store.state.activeAccountProfile?.color
                                ?? Asset.Colors.primaryBitwarden.swiftUIColor
                        )
                        .clipShape(Circle())
                    Spacer()
                }
                .frame(minWidth: 50)
                .fixedSize()
            } else {
                EmptyView()
            }
        }
        .accessibilityIdentifier("AccountIconButton")
        .accessibilityLabel(Localizations.account)
    }
}

// MARK: Previews

#if DEBUG
struct ProfileSwitcherToolbarView_Previews: PreviewProvider {
    static let selectedAccount = ProfileSwitcherItem(
        color: .purple,
        email: "anne.account@bitwarden.com",
        isUnlocked: true,
        userId: "1",
        userInitials: "AA"
    )

    static var previews: some View {
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

        NavigationView {
            Spacer()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        ProfileSwitcherToolbarView(
                            store: Store(
                                processor: StateProcessor(
                                    state: .init(
                                        accounts: [selectedAccount],
                                        activeAccountId: nil,
                                        isVisible: false
                                    )
                                )
                            )
                        )
                    }
                }
        }
        .previewDisplayName("No Active")

        NavigationView {
            Spacer()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        ProfileSwitcherToolbarView(
                            store: Store(
                                processor: StateProcessor(
                                    state: ProfileSwitcherState(
                                        accounts: [
                                            selectedAccount,
                                        ],
                                        activeAccountId: selectedAccount.userId,
                                        isVisible: false
                                    )
                                )
                            )
                        )
                    }
                }
        }
        .previewDisplayName("Single Account")

        NavigationView {
            Spacer()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        ProfileSwitcherToolbarView(
                            store: Store(
                                processor: StateProcessor(
                                    state: ProfileSwitcherState(
                                        accounts: [
                                            selectedAccount,
                                            ProfileSwitcherItem(
                                                color: .green,
                                                email: "bonus.bridge@bitwarde.com",
                                                isUnlocked: true,
                                                userId: "123",
                                                userInitials: "BB"
                                            ),
                                        ],
                                        activeAccountId: "123",
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
}
#endif
