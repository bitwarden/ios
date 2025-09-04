import BitwardenKit
import BitwardenResources
import SwiftUI

public struct ProfileSwitcherSheet: View {
    /// The `Store` for this view.
    @ObservedObject var store: Store<ProfileSwitcherState, ProfileSwitcherAction, ProfileSwitcherEffect>

    @SwiftUI.State var scrollOffset = CGPoint.zero

    public var body: some View {
        ZStack {
            SharedAsset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea()

            SectionView(Localizations.selectAccount) {
                accounts
                if store.state.showsAddAccount {
                    addAccountRow
                }
            }
            .padding(.horizontal, 12)
        }
        .navigationBar(title: Localizations.accountsPluralNoun, titleDisplayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                closeToolbarButton {
                    store.send(.dismissTapped)
                }
            }
        }
        .task {
            await store.perform(.refreshAccountProfiles)
        }
//        .accessibilityAction(named: Localizations.close) {
//            store.send(.backgroundPressed)
//        }
    }

    // MARK: Private Properties

    /// A row to add an account
    @ViewBuilder private var addAccountRow: some View {
        AsyncButton {
            await store.perform(.addAccountPressed)
        } label: {
            Label(Localizations.addAccount, image: Asset.Images.plus16.swiftUIImage)
        }
        .buttonStyle(.bitwardenBorderless)
        .frame(maxWidth: .infinity, alignment: .center)
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// A row to display the active account profile
    ///
    /// - Parameter accountProfile: A `ProfileSwitcherItem` to display in row format
    ///
    @ViewBuilder private var selectedProfileSwitcherRow: some View {
        if let profile = store.state.activeAccountProfile {
            profileSwitcherRow(
                accountProfile: profile,
                showDivider: false
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
@available(iOS 16.0, *)
#Preview("Single Account") {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            NavigationView {
                ProfileSwitcherSheet(
                    store: Store(
                        processor: StateProcessor(
                            state: .singleAccount
                        )
                    )
                )
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
}

@available(iOS 16.0, *)
#Preview("Dual Account") {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            NavigationView {
                ProfileSwitcherSheet(
                    store: Store(
                        processor: StateProcessor(
                            state: .dualAccounts
                        )
                    )
                )
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
}

@available(iOS 16.0, *)
#Preview("Many Accounts") {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            NavigationView {
                ProfileSwitcherSheet(
                    store: Store(
                        processor: StateProcessor(
                            state: .subMaximumAccounts
                        )
                    )
                )
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
}

@available(iOS 16.0, *)
#Preview("Max Accounts") {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            NavigationView {
                ProfileSwitcherSheet(
                    store: Store(
                        processor: StateProcessor(
                            state: .maximumAccounts
                        )
                    )
                )
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
}
#endif
