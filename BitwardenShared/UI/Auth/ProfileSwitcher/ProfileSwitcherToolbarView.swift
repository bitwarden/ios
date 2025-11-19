import BitwardenKit
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
        let tintColor = store.state.showPlaceholderToolbarIcon
            ? nil
            : store.state.activeAccountProfile?.color
        // iOS 26+ uses the tint color on liquid glass to give the button its color. Prior to iOS 26,
        // the button's background is colored in `profileSwitcherIcon`.
        let iconColor: Color? = if #available(iOS 26, *) { nil } else { tintColor }

        let iconSize: ProfileSwitcherIconSize = if #available(iOS 26, *) { .toolbar } else { .standard }
        // On iOS 26+, remove extra padding applied around the button, which allows the initials
        // font size to scale larger without increasing the overall width of the button.
        let horizontalPadding: CGFloat = if #available(iOS 26, *) { -4 } else { 0 }

        AsyncButton {
            await store.perform(.requestedProfileSwitcher(visible: !store.state.isVisible))
        } label: {
            profileSwitcherIcon(
                color: iconColor,
                initials: store.state.showPlaceholderToolbarIcon
                    ? nil
                    : store.state.activeAccountProfile?.userInitials,
                textColor: store.state.showPlaceholderToolbarIcon
                    ? nil
                    : store.state.activeAccountProfile?.profileIconTextColor,
                size: iconSize,
            )
        }
        .backport.buttonStyleGlassProminent()
        .tint(tintColor ?? SharedAsset.Colors.backgroundTertiary.swiftUIColor)
        .padding(.horizontal, horizontalPadding)
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
    ///   - size: The size configuration for the icon.
    ///
    @ViewBuilder
    func profileSwitcherIcon(
        color: Color? = SharedAsset.Colors.backgroundTertiary.swiftUIColor,
        initials: String?,
        textColor: Color?,
        size: ProfileSwitcherIconSize = .standard,
    ) -> some View {
        Text(initials ?? "  ")
            .styleGuide(size.textStyle, weight: size.fontWeight)
            .padding(size.padding)
            .frame(minWidth: 22, alignment: .center)
            .background {
                if initials == nil {
                    SharedAsset.Icons.horizontalDots16.swiftUIImage
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .opacity(initials == nil ? 1.0 : 0.0)
                        .accessibilityHidden(initials != nil)
                }
            }
            .foregroundColor(textColor ?? SharedAsset.Colors.textInteraction.swiftUIColor)
            .background(color)
            .if(size.shouldClipToCircle) { view in
                view.clipShape(Circle())
            }
    }
}

// MARK: - ProfileSwitcherIconSize

/// Size configurations for profile switcher icons.
///
struct ProfileSwitcherIconSize {
    // MARK: Properties

    /// The font weight for the user's initials.
    let fontWeight: SwiftUI.Font.Weight

    /// The padding to apply to the user's initials.
    let padding: CGFloat

    /// The text style for the user's initials.
    let textStyle: StyleGuideFont

    /// Whether the user's initials and background should be clipped to a circle.
    let shouldClipToCircle: Bool
}

extension ProfileSwitcherIconSize {
    /// The standard icon size for the profile switcher and toolbar pre-iOS 26.
    static let standard = ProfileSwitcherIconSize(
        fontWeight: .regular,
        padding: 4,
        textStyle: .caption2Monospaced,
        shouldClipToCircle: true,
    )

    /// A larger icon size for use as a toolbar icon on iOS 26+.
    static let toolbar = ProfileSwitcherIconSize(
        fontWeight: .semibold,
        padding: 0,
        textStyle: .bodyMonospaced,
        shouldClipToCircle: false,
    )
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
                                state: .empty(),
                            ),
                        ),
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
                                    isVisible: false,
                                ),
                            ),
                        ),
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
                                state: .singleAccount,
                            ),
                        ),
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
                                    isVisible: false,
                                ),
                            ),
                        ),
                    )
                }
            }
    }
}
#endif
