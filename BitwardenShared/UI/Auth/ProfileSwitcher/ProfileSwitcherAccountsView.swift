import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - ProfileSwitcherAccountsView

/// A view listing the accounts displayed in the account switcher. These are shared between
/// `ProfileSwitcherSheet` and `ProfileSwitcherView`, and therefore are on iOS both pre-26 and 26.
///
struct ProfileSwitcherAccountsView: View {
    @ObservedObject var store: Store<ProfileSwitcherState, ProfileSwitcherAction, ProfileSwitcherEffect>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEachIndexed(store.state.alternateAccounts, id: \.self) { _, account in
                profileSwitcherRow(accountProfile: account)
            }
            selectedProfileSwitcherRow
        }
    }

    /// A row to display the active account profile, if there is one.
    ///
    @ViewBuilder private var selectedProfileSwitcherRow: some View {
        if let profile = store.state.activeAccountProfile {
            profileSwitcherRow(
                accountProfile: profile,
                showDivider: false,
            )
        }
    }

    // MARK: Private Methods

    /// A row to display an account profile.
    ///
    /// - Parameters:
    ///   - accountProfile: A `ProfileSwitcherItem` to display in row format.
    ///   - showDivider: Should the cell show a divider at the bottom.
    ///
    @ViewBuilder
    private func profileSwitcherRow(
        accountProfile: ProfileSwitcherItem,
        showDivider: Bool = true,
    ) -> some View {
        let isActive = accountProfile.userId == store.state.activeAccountId
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
                            : "InactiveVaultIcon",
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
                },
            ),
        )
    }
}
