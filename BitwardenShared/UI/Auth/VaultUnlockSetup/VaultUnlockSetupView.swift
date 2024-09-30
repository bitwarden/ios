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
        VStack(spacing: 32) {
            PageHeaderView(
                image: Asset.Images.biometricsPhone,
                title: Localizations.setUpUnlock,
                message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
            )

            VStack(spacing: 0) {
                ForEach(store.state.unlockMethods) { unlockMethod in
                    Toggle(isOn: store.bindingAsync(
                        get: { $0[keyPath: unlockMethod.keyPath] },
                        perform: { VaultUnlockSetupEffect.toggleUnlockMethod(unlockMethod, newValue: $0) }
                    )) {
                        Text(unlockMethod.title)
                            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    }
                    .accessibilityIdentifier(unlockMethod.accessibilityIdentifier)
                    .toggleStyle(.bitwarden)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)

                    if unlockMethod != store.state.unlockMethods.last {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(spacing: 12) {
                AsyncButton(Localizations.continue) {
                    await store.perform(.continueFlow)
                }
                .buttonStyle(.primary())
                .disabled(!store.state.isContinueButtonEnabled)

                Button(Localizations.setUpLater) {
                    store.send(.setUpLater)
                }
                .buttonStyle(.transparent)
            }
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBar(title: Localizations.accountSetup, titleDisplayMode: .inline)
        .scrollView()
        .task {
            await store.perform(.loadData)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("VaultUnlockSetup") {
    VaultUnlockSetupView(store: Store(processor: StateProcessor(state: VaultUnlockSetupState())))
}
#endif
