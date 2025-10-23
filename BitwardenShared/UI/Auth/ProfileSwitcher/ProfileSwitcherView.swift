import BitwardenKit
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
            offset: $scrollOffset,
        ) {
            VStack(spacing: 0.0) {
                ProfileSwitcherAccountsView(store: store)
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
            store.send(.backgroundTapped)
        }
        .allowsHitTesting(store.state.isVisible)
        .animation(.easeInOut(duration: 0.2), value: store.state.isVisible)
        .accessibilityHidden(!store.state.isVisible)
        .accessibilityAction(named: Localizations.close) {
            store.send(.backgroundTapped)
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
                    rowType: .addAccount,
                )
            },
            mapAction: nil,
            mapEffect: { _ in
                .addAccountPressed
            },
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
}

// MARK: Previews

#if DEBUG
struct ProfileSwitcherView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileSwitcherView(
                store: Store(
                    processor: StateProcessor(
                        state: .singleAccount,
                    ),
                ),
            )
        }
        .previewDisplayName("Single Account")

        NavigationView {
            ProfileSwitcherView(
                store: Store(
                    processor: StateProcessor(
                        state: .dualAccounts,
                    ),
                ),
            )
        }
        .previewDisplayName("Dual Account")

        NavigationView {
            ProfileSwitcherView(
                store: Store(
                    processor: StateProcessor(
                        state: .subMaximumAccounts,
                    ),
                ),
            )
        }
        .previewDisplayName("Many Accounts")

        NavigationView {
            ProfileSwitcherView(
                store: Store(
                    processor: StateProcessor(
                        state: .maximumAccounts,
                    ),
                ),
            )
        }
        .previewDisplayName("Max Accounts")
    }
}
#endif
