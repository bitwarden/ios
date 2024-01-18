import SwiftUI

// MARK: - ProfileSwitcherView

/// A view that allows the user to view, select, and add profiles.
///
struct ProfileSwitcherView: View {
    /// The `Store` for this view.
    @ObservedObject var store: Store<ProfileSwitcherState, ProfileSwitcherAction, ProfileSwitcherEffect>

    var body: some View {
        OffsetObservingScrollView(
            axes: store.state.isVisible ? .vertical : [],
            offset: .init(
                get: { store.state.scrollOffset },
                set: { store.send(.scrollOffsetChanged($0)) }
            )
        ) {
            VStack(spacing: 0.0) {
                accounts
                if store.state.showsAddAccount {
                    addAccountRow
                }
            }
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
            .transition(.move(edge: .top))
            .hidden(!store.state.isVisible)
            .fixedSize(horizontal: false, vertical: true)
        }
        .background {
            backgroundView
                .hidden(!store.state.isVisible)
                .accessibilityHidden(!store.state.isVisible)
                .accessibilityLabel(Localizations.close)
                .accessibility(addTraits: .isButton)
                .accessibilityAction {
                    store.send(.backgroundPressed)
                }
        }
        .onTapGesture {
            store.send(.backgroundPressed)
        }
        .allowsHitTesting(store.state.isVisible)
        .animation(.easeInOut(duration: 0.2), value: store.state.isVisible)
    }

    // MARK: Private Properties

    /// A row to add an account
    @ViewBuilder private var addAccountRow: some View {
        ProfileSwitcherRow(store: store.child(
            state: { _ in
                .init(
                    shouldTakeAccessibilityFocus: false,
                    showDivider: false,
                    rowType: .addAccount
                )
            },
            mapAction: { _ in .addAccountPressed },
            mapEffect: nil
        ))
        .accessibilityIdentifier("AddAccountButton")
    }

    /// A background view with accessibility enabled
    private var backgroundView: some View {
        VStack {
            Asset.Colors.backgroundPrimary.swiftUIColor
                .frame(height: abs(min(store.state.scrollOffset.y, 0)))
                .fixedSize(horizontal: false, vertical: true)
            Color.black.opacity(0.4)
                .ignoresSafeArea()
        }
        .hidden(!store.state.isVisible)
    }

    /// A group of account views
    private var accounts: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEachIndexed(store.state.alternateAccounts, id: \.self) { _, account in
                unselectedProfileSwitcherRow(accountProfile: account)
            }
            selectedProfileSwitcherRow
        }
    }

    /// A row to display the active account profile
    ///
    /// - Parameter accountProfile: A `ProfileSwitcherItem` to display in row format
    ///
    private var selectedProfileSwitcherRow: some View {
        ProfileSwitcherRow(store: store.child(
            state: { state in
                ProfileSwitcherRowState(
                    shouldTakeAccessibilityFocus: state.isVisible,
                    showDivider: state.showsAddAccount,
                    rowType: .active(
                        state.activeAccountProfile ?? ProfileSwitcherItem()
                    )
                )
            },
            mapAction: { action in
                switch action {
                case .longPressed:
                    .accountLongPressed(store.state.activeAccountProfile ?? ProfileSwitcherItem())
                case .pressed:
                    .accountPressed(store.state.activeAccountProfile ?? ProfileSwitcherItem())
                }
            },
            mapEffect: nil
        ))
    }

    // MARK: Private Methods

    /// A row to display an alternate account profile
    ///
    /// - Parameter accountProfile: A `ProfileSwitcherItem` to display in row format
    ///
    @ViewBuilder
    private func unselectedProfileSwitcherRow(
        accountProfile: ProfileSwitcherItem
    ) -> some View {
        ProfileSwitcherRow(
            store: store.child(
                state: { _ in
                    ProfileSwitcherRowState(
                        shouldTakeAccessibilityFocus: false,
                        rowType: .alternate(accountProfile)
                    )
                },
                mapAction: { action in
                    switch action {
                    case .longPressed:
                        .accountLongPressed(accountProfile)
                    case .pressed:
                        .accountPressed(accountProfile)
                    }
                },
                mapEffect: nil
            )
        )
    }
}

// MARK: Previews

#if DEBUG
struct ProfileSwitcherView_Previews: PreviewProvider {
    static let selectedAccount = ProfileSwitcherItem(
        color: .purple,
        email: "anne.account@bitwarden.com",
        userId: "1",
        userInitials: "AA"
    )

    static var previews: some View {
        NavigationView {
            ProfileSwitcherView(
                store: Store(
                    processor: StateProcessor(
                        state: ProfileSwitcherState(
                            accounts: [
                                selectedAccount,
                            ],
                            activeAccountId: selectedAccount.userId,
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
                            accounts: [
                                selectedAccount,
                                ProfileSwitcherItem(
                                    color: .green,
                                    email: "bonus.bridge@bitwarde.com",
                                    isUnlocked: true,
                                    userInitials: "BB"
                                ),
                            ],
                            activeAccountId: selectedAccount.userId,
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
                            accounts: [
                                selectedAccount,
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
                            ],
                            activeAccountId: "1",
                            isVisible: true
                        )
                    )
                )
            )
        }
        .previewDisplayName("Many Accounts")

        NavigationView {
            ProfileSwitcherView(
                store: Store(
                    processor: StateProcessor(
                        state: ProfileSwitcherState(
                            accounts: [
                                selectedAccount,
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
                            activeAccountId: "1",
                            isVisible: true
                        )
                    )
                )
            )
        }
        .previewDisplayName("Max Accounts")
    }
}
#endif
