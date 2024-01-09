import SwiftUI

// MARK: - LoginWithPINView

/// A view allowing the user to login with their PIN.
///
struct LoginWithPINView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<LoginWithPINState, LoginWithPINAction, LoginWithPINEffect>

    // MARK: View

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 24) {
                textfield

                unlockButton
            }
            .scrollView()

            profileSwitcher
        }
        .task {
            await store.perform(.appeared)
        }
        .navigationTitle(Localizations.verifyPIN)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                profileSwitcherToolbarView
            }
            moreToolbarItem {
                AsyncButton {
                    await store.perform(.logout)
                } label: {
                    Text(Localizations.logOut)
                }
            }
        }
    }

    // MARK: Private views

    /// A view that displays the ability to add or switch between account profiles
    @ViewBuilder private var profileSwitcher: some View {
        ProfileSwitcherView(
            store: store.child(
                state: { vaultListState in
                    vaultListState.profileSwitcherState
                },
                mapAction: { action in
                    .profileSwitcherAction(action)
                },
                mapEffect: { profileEffect in
                    .profileSwitcher(profileEffect)
                }
            )
        )
    }

    /// The profile switcher toolbar view.
    @ViewBuilder private var profileSwitcherToolbarView: some View {
        ProfileSwitcherToolbarView(
            store: store.child(
                state: { state in
                    state.profileSwitcherState
                },
                mapAction: { action in
                    .profileSwitcherAction(action)
                },
                mapEffect: nil
            )
        )
    }

    /// The text field for the PIN.
    private var textfield: some View {
        BitwardenTextField(
            title: Localizations.pin,
            text: store.binding(
                get: \.pinCode,
                send: LoginWithPINAction.pinChanged
            ),
            footer: "\(Localizations.vaultLockedPIN)\n\(Localizations.loggedInAsOn("1", "2"))",
            accessibilityIdentifier: "PINEntry",
            isPasswordVisible: store.binding(
                get: \.isPINVisible,
                send: LoginWithPINAction.showPIN
            ),
            passwordVisibilityAccessibilityId: "PINVisibilityToggle"
        )
        .textFieldConfiguration(.password)
    }

    /// The unlock button.
    private var unlockButton: some View {
        AsyncButton {
            await store.perform(.unlockWithPIN)
        } label: {
            Text(Localizations.unlock)
        }
        .buttonStyle(.primary())
    }
}

#Preview {
    LoginWithPINView(store: Store(processor: StateProcessor(state: LoginWithPINState())))
}
