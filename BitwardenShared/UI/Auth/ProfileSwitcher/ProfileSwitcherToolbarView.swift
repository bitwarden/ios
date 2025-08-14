import BitwardenResources
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
        AsyncButton {
            await store.perform(.requestedProfileSwitcher(visible: !store.state.isVisible))
        } label: {
            profileSwitcherIcon(
                color: store.state.showPlaceholderToolbarIcon
                    ? nil
                    : store.state.activeAccountProfile?.color,
                initials: store.state.showPlaceholderToolbarIcon
                    ? nil
                    : store.state.activeAccountProfile?.userInitials,
                textColor: store.state.showPlaceholderToolbarIcon
                    ? nil
                    : store.state.activeAccountProfile?.profileIconTextColor
            )
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
                    Asset.Images.horizontalDots16.swiftUIImage
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .opacity(initials == nil ? 1.0 : 0.0)
                        .accessibilityHidden(initials != nil)
                }
            }
            .foregroundColor(textColor ?? SharedAsset.Colors.textInteraction.swiftUIColor)
            .background(color ?? SharedAsset.Colors.backgroundTertiary.swiftUIColor)
            .clipShape(Circle())
    }
}

// MARK: Previews

#if DEBUG
#Preview("Empty") {
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
}

#Preview("No Active") {
    NavigationView {
        Spacer()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ProfileSwitcherToolbarView(
                        store: Store(
                            processor: StateProcessor(
                                state: .init(
                                    accounts: [.anneAccount],
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
}

#Preview("Single Account") {
    NavigationView {
        Spacer()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ProfileSwitcherToolbarView(
                        store: Store(
                            processor: StateProcessor(
                                state: .singleAccount
                            )
                        )
                    )
                }
            }
    }
}

#Preview("Dual Account") {
    NavigationView {
        Spacer()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ProfileSwitcherToolbarView(
                        store: Store(
                            processor: StateProcessor(
                                state: ProfileSwitcherState(
                                    accounts: [
                                        .anneAccount,
                                        .fixture(color: .green, userId: "1", userInitials: "BB"),
                                    ],
                                    activeAccountId: "1",
                                    allowLockAndLogout: true,
                                    isVisible: false
                                )
                            )
                        )
                    )
                }
            }
    }
}
#endif
