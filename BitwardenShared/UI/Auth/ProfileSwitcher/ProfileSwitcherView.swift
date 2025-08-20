import BitwardenResources
import SwiftUI

// MARK: - ProfileSwitcherView

/// A view that allows the user to view, select, and add profiles.
///
struct ProfileSwitcherView: View {
    /// The `Store` for this view.
    @ObservedObject var store: Store<ProfileSwitcherState, ProfileSwitcherAction, ProfileSwitcherEffect>

    @SwiftUI.State var scrollOffset = CGPoint.zero

    var body: some View {
        OffsetObservingScrollView(
            axes: .vertical,
            offset: $scrollOffset
        ) {
            VStack(spacing: 0.0) {
                accounts
                if store.state.showsAddAccount {
                    addAccountRow
                }
            }
            .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
            .transition(.move(edge: .top))
            .hidden(!store.state.isVisible)
            .fixedSize(horizontal: false, vertical: true)
        }
        .background {
            backgroundView
                .hidden(!store.state.isVisible)
                .accessibilityHidden(true)
        }
        .onTapGesture {
            store.send(.backgroundPressed)
        }
        .allowsHitTesting(store.state.isVisible)
        .animation(.easeInOut(duration: 0.2), value: store.state.isVisible)
        .accessibilityHidden(!store.state.isVisible)
        .accessibilityAction(named: Localizations.close) {
            store.send(.backgroundPressed)
        }
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
            mapAction: nil,
            mapEffect: { _ in
                .addAccountPressed
            }
        ))
        .accessibilityIdentifier("AddAccountButton")
    }

    /// A background view with accessibility enabled
    private var backgroundView: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            SharedAsset.Colors.backgroundSecondary.swiftUIColor
                .frame(height: abs(min(scrollOffset.y, 0)))
                .fixedSize(horizontal: false, vertical: true)
        }
        .hidden(!store.state.isVisible)
    }

    /// A group of account views
    private var accounts: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEachIndexed(store.state.alternateAccounts, id: \.self) { _, account in
                profileSwitcherRow(accountProfile: account)
            }
            selectedProfileSwitcherRow
        }
    }

    /// A row to display the active account profile
    ///
    /// - Parameter accountProfile: A `ProfileSwitcherItem` to display in row format
    ///
    @ViewBuilder private var selectedProfileSwitcherRow: some View {
        if let profile = store.state.activeAccountProfile {
            profileSwitcherRow(
                accountProfile: profile,
                showDivider: store.state.showsAddAccount
            )
        }
    }

    // MARK: Private Methods

    /// A row to display an account profile
    ///
    /// - Parameters
    ///     - accountProfile: A `ProfileSwitcherItem` to display in row format
    ///     - showDivider: Should the cell show a divider at the bottom.
    ///
    @ViewBuilder
    private func profileSwitcherRow(
        accountProfile: ProfileSwitcherItem,
        showDivider: Bool = true
    ) -> some View {
        let isActive = (accountProfile.userId == store.state.activeAccountId)
        ProfileSwitcherRow(
            store: store.child(
                state: { _ in
                    ProfileSwitcherRowState(
                        allowLockAndLogout: store.state.allowLockAndLogout,
                        shouldTakeAccessibilityFocus: store.state.isVisible
                            && isActive,
                        showDivider: showDivider,
                        rowType: isActive
                            ? .active(accountProfile)
                            : .alternate(accountProfile),
                        trailingIconAccessibilityID: isActive
                            ? "ActiveVaultIcon"
                            : "InactiveVaultIcon"
                    )
                },
                mapAction: { action in
                    switch action {
                    case let .accessibility(accessibilityAction):
                        switch accessibilityAction {
                        case .logout:
                            .accessibility(.logout(accountProfile))
                        case .remove:
                            .accessibility(.remove(accountProfile))
                        }
                    }
                },
                mapEffect: { effect in
                    switch effect {
                    case let .accessibility(accessibility):
                        switch accessibility {
                        case .lock:
                            .accessibility(.lock(accountProfile))
                        case .select:
                            .accessibility(.select(accountProfile))
                        }
                    case .longPressed:
                        .accountLongPressed(accountProfile)
                    case .pressed:
                        .accountPressed(accountProfile)
                    }
                }
            )
        )
    }
}

// MARK: Previews

#if DEBUG
struct ProfileSwitcherView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileSwitcherView(
                store: Store(
                    processor: StateProcessor(
                        state: .singleAccount
                    )
                )
            )
        }
        .previewDisplayName("Single Account")

        NavigationView {
            ProfileSwitcherView(
                store: Store(
                    processor: StateProcessor(
                        state: .dualAccounts
                    )
                )
            )
        }
        .previewDisplayName("Dual Account")

        NavigationView {
            ProfileSwitcherView(
                store: Store(
                    processor: StateProcessor(
                        state: .subMaximumAccounts
                    )
                )
            )
        }
        .previewDisplayName("Many Accounts")

        NavigationView {
            ProfileSwitcherView(
                store: Store(
                    processor: StateProcessor(
                        state: .maximumAccounts
                    )
                )
            )
        }
        .previewDisplayName("Max Accounts")
    }
}
#endif
