import BitwardenResources
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
            mainContent
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

    // MARK: Private Views

    /// The Toolbar item for the profile switcher view
    private var profileSwitcherToolbarItem: some View {
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
    private var profileSwitcher: some View {
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

    /// The main content of the view
    private var mainContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                Image(decorative: Asset.Images.logo)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(SharedAsset.Colors.iconSecondary.swiftUIColor)
                    .frame(maxWidth: .infinity, maxHeight: 34)
                    .padding(.horizontal, 12)

                Spacer(minLength: 24)

                landingDetails
            }
            .padding(.bottom, 16)
            .frame(minHeight: geometry.size.height)
            .scrollView(addVerticalPadding: false, showsIndicators: false)
        }
    }

    /// The section of the view containing input fields, and action buttons.
    private var landingDetails: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(Localizations.logInToBitwarden)
                .styleGuide(.title2, weight: .semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                BitwardenTextField(
                    title: Localizations.emailAddress,
                    text: store.binding(
                        get: \.email,
                        send: LandingAction.emailChanged
                    ),
                    accessibilityIdentifier: "LoginEmailAddressEntry",
                    footerContent: {
                        RegionSelector(
                            selectorLabel: Localizations.loggingInOn,
                            regionName: store.state.region.baseURLDescription
                        ) {
                            await store.perform(.regionPressed)
                        }
                        .padding(.vertical, 14)
                    }
                )
                .textFieldConfiguration(.email)
                .onSubmit {
                    guard store.state.isContinueButtonEnabled else { return }
                    Task { await store.perform(.continuePressed) }
                }

                BitwardenToggle(Localizations.rememberMe, isOn: store.binding(
                    get: { $0.isRememberMeOn },
                    send: { .rememberMeChanged($0) }
                ))
                .accessibilityIdentifier("RememberMeSwitch")
                .contentBlock()
            }

            AsyncButton(Localizations.continue) {
                await store.perform(.continuePressed)
            }
            .accessibilityIdentifier("ContinueButton")
            .disabled(!store.state.isContinueButtonEnabled)
            .buttonStyle(.primary())

            HStack(spacing: 4) {
                Spacer()
                Text(Localizations.newAroundHere)
                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                Button(Localizations.createAccount) {
                    store.send(.createAccountPressed)
                }
                .accessibilityIdentifier("CreateAccountButton")
                .foregroundColor(SharedAsset.Colors.textInteraction.swiftUIColor)
                Spacer()
            }
            .styleGuide(.footnote)

            Button {
                store.send(.showPreLoginSettings)
            } label: {
                Label(Localizations.appSettings, image: Asset.Images.cog16.swiftUIImage)
            }
            .buttonStyle(.bitwardenBorderless)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Empty Email") {
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
}

#Preview("Example Email") {
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
}

#Preview("Profiles Closed") {
    NavigationView {
        LandingView(
            store: Store(
                processor: StateProcessor(
                    state: LandingState(
                        email: "",
                        isRememberMeOn: false,
                        profileSwitcherState: ProfileSwitcherState.singleAccountHidden
                    )
                )
            )
        )
    }
}

#Preview("Profiles Open") {
    NavigationView {
        LandingView(
            store: Store(
                processor: StateProcessor(
                    state: LandingState(
                        email: "",
                        isRememberMeOn: false,
                        profileSwitcherState: ProfileSwitcherState.singleAccount
                    )
                )
            )
        )
    }
}
#endif
