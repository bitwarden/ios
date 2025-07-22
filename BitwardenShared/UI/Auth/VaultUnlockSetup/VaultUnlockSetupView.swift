import BitwardenResources
import SwiftUI

// MARK: - VaultUnlockSetupView

/// A view that allows the user to enable vault unlock methods when setting up their account.
///
struct VaultUnlockSetupView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultUnlockSetupState, VaultUnlockSetupAction, VaultUnlockSetupEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 24) {
            IllustratedMessageView(
                image: Asset.Images.Illustrations.biometricsPhone,
                title: Localizations.setUpUnlock,
                message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
            )
            .padding(.top, 12)

            ContentBlock(dividerLeadingPadding: 12) {
                ForEach(store.state.unlockMethods) { unlockMethod in
                    Toggle(isOn: store.bindingAsync(
                        get: { $0[keyPath: unlockMethod.keyPath] },
                        perform: { VaultUnlockSetupEffect.toggleUnlockMethod(unlockMethod, newValue: $0) }
                    )) {
                        Text(unlockMethod.title)
                            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    }
                    .accessibilityIdentifier(unlockMethod.accessibilityIdentifier)
                    .toggleStyle(.bitwarden)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
            }

            VStack(spacing: 12) {
                AsyncButton(Localizations.continue) {
                    await store.perform(.continueFlow)
                }
                .buttonStyle(.primary())
                .disabled(!store.state.isContinueButtonEnabled)

                if store.state.shouldDisplaySetUpLaterButton {
                    Button(Localizations.setUpLater) {
                        store.send(.setUpLater)
                    }
                    .buttonStyle(.secondary())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBar(title: store.state.navigationBarTitle, titleDisplayMode: .inline)
        .scrollView()
        .task {
            await store.perform(.loadData)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Create Account Flow") {
    VaultUnlockSetupView(store: Store(processor: StateProcessor(state: VaultUnlockSetupState(
        accountSetupFlow: .createAccount
    ))))
    .navStackWrapped
}

#Preview("Settings Flow") {
    VaultUnlockSetupView(store: Store(processor: StateProcessor(state: VaultUnlockSetupState(
        accountSetupFlow: .settings
    ))))
    .navStackWrapped
}
#endif
