import SwiftUI

// MARK: - LandingView

/// A view that allows the user to input their email address to begin the login flow,
/// or allows the user to navigate to the account creation flow.
///
struct LandingView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject public var store: Store<LandingState, LandingAction, LandingEffect>

    var body: some View {
        ZStack {
            scrollingContent
            profileSwitcher
        }
        .navigationBarTitle(Localizations.bitwarden, displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                profileSwitcherToolbarItem
            }
        }
        .task {
            await store.perform(.appeared)
        }
        .toast(store.binding(
            get: \.toast,
            send: LandingAction.toastShown
        ))
    }

    /// The Toolbar item for the profile switcher view
    @ViewBuilder var profileSwitcherToolbarItem: some View {
        ProfileSwitcherToolbarView(
            store: store.child(
                state: { state in
                    state.profileSwitcherState
                },
                mapAction: { action in
                    .profileSwitcher(action)
                },
                mapEffect: { effect in
                    .profileSwitcher(effect)
                }
            )
        )
    }

    /// A view that displays the ability to add or switch between account profiles
    @ViewBuilder private var profileSwitcher: some View {
        ProfileSwitcherView(
            store: store.child(
                state: { mainState in
                    mainState.profileSwitcherState
                },
                mapAction: { action in
                    .profileSwitcher(action)
                },
                mapEffect: { profileEffect in
                    .profileSwitcher(profileEffect)
                }
            )
        )
    }

    /// The main scrollable content of the view
    var scrollingContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(decorative: Asset.Images.logo)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 45)

                Text(Localizations.loginOrCreateNewAccount)
                    .styleGuide(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .frame(maxWidth: .infinity)

                BitwardenTextField(
                    title: Localizations.emailAddress,
                    text: store.binding(
                        get: \.email,
                        send: LandingAction.emailChanged
                    ),
                    accessibilityIdentifier: "EmailAddressEntry"
                )
                .textFieldConfiguration(.email)
                .onSubmit {
                    guard store.state.isContinueButtonEnabled else { return }
                    store.send(.continuePressed)
                }

                Button {
                    store.send(.regionPressed)
                } label: {
                    HStack(spacing: 4) {
                        Group {
                            Text("\(Localizations.loggingInOn): ")
                                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                + Text(store.state.region.baseUrlDescription)
                                .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                        }
                        .styleGuide(.subheadline)

                        Image(decorative: Asset.Images.downAngle)
                            .resizable()
                            .frame(width: 12, height: 12)
                            .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                    }
                }
                .accessibilityIdentifier("RegionSelectorDropdown")

                Toggle(Localizations.rememberMe, isOn: store.binding(
                    get: { $0.isRememberMeOn },
                    send: { .rememberMeChanged($0) }
                ))
                .accessibilityIdentifier("RememberMeSwitch")
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .toggleStyle(.bitwarden)

                Button(Localizations.continue) {
                    store.send(.continuePressed)
                }
                .accessibilityIdentifier("ContinueButton")
                .disabled(!store.state.isContinueButtonEnabled)
                .buttonStyle(.primary())

                HStack(spacing: 4) {
                    Text(Localizations.newAroundHere)
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    Button(Localizations.createAccount) {
                        store.send(.createAccountPressed)
                    }
                    .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                }
                .styleGuide(.footnote)
            }
            .padding([.horizontal, .bottom], 16)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        LandingView(
            store: Store(
                processor: StateProcessor(
                    state: LandingState(
                        email: "",
                        isRememberMeOn: false
                    )
                )
            )
        )
    }
    .previewDisplayName("Empty Email")
}

#Preview {
    NavigationView {
        LandingView(
            store: Store(
                processor: StateProcessor(
                    state: LandingState(
                        email: "email@example.com",
                        isRememberMeOn: true
                    )
                )
            )
        )
    }
    .previewDisplayName("Example Email")
}

#Preview {
    NavigationView {
        LandingView(
            store: Store(
                processor: StateProcessor(
                    state: LandingState(
                        email: "",
                        isRememberMeOn: false,
                        profileSwitcherState: ProfileSwitcherState(
                            accounts: [
                                ProfileSwitcherItem(
                                    email: "max.protecc@bitwarden.com",
                                    isUnlocked: false,
                                    userId: "123",
                                    userInitials: "MP",
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
        )
    }
    .previewDisplayName("Profiles Closed")
}

#Preview {
    NavigationView {
        LandingView(
            store: Store(
                processor: StateProcessor(
                    state: LandingState(
                        email: "",
                        isRememberMeOn: false,
                        profileSwitcherState: ProfileSwitcherState(
                            accounts: [
                                ProfileSwitcherItem(
                                    email: "max.protecc@bitwarden.com",
                                    isUnlocked: false,
                                    userId: "123",
                                    userInitials: "MP",
                                    webVault: ""
                                ),
                            ],
                            activeAccountId: "123",
                            allowLockAndLogout: true,
                            isVisible: true
                        )
                    )
                )
            )
        )
    }
    .previewDisplayName("Profiles Open")
}
#endif
