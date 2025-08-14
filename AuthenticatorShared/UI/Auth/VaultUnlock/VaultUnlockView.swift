import BitwardenResources
import SwiftUI

// MARK: - VaultUnlockView

/// A view that allows a user to use biometrics before viewing their items
///
struct VaultUnlockView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultUnlockState, VaultUnlockAction, VaultUnlockEffect>

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .task {
                await store.perform(.appeared)
            }
            .toast(store.binding(
                get: \.toast,
                send: VaultUnlockAction.toastShown
            ))
    }

    private var content: some View {
        ZStack {
            if colorScheme == .light {
                Asset.Colors.primaryBitwarden.swiftUIColor
            } else {
                Asset.Colors.backgroundSecondary.swiftUIColor
            }

            Image(decorative: Asset.Images.authenticatorLogo)
                .resizable()
                .frame(width: 232, height: 63)

            biometricAuthButton
                .offset(y: 63 + 48)
                .padding(16)
        }
        .ignoresSafeArea()
    }

    /// A button to trigger a biometric auth unlock.
    @ViewBuilder private var biometricAuthButton: some View {
        if case let .available(biometryType, true, true) = store.state.biometricUnlockStatus {
            AsyncButton {
                Task { await store.perform(.unlockWithBiometrics) }
            } label: {
                biometricUnlockText(biometryType)
            }
            .if(colorScheme == .light) { view in
                view.buttonStyle(.secondary(shouldFillWidth: true))
                    .background(Asset.Colors.backgroundPrimary.swiftUIColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .if(colorScheme == .dark) { view in
                view.buttonStyle(.primary(shouldFillWidth: true))
            }
        }
    }

    private func biometricUnlockText(_ biometryType: BiometricAuthenticationType) -> some View {
        switch biometryType {
        case .faceID:
            Text(Localizations.useFaceIDToUnlock)
        case .touchID:
            Text(Localizations.useFingerprintToUnlock)
        }
    }
}

// MARK: - Previews

#if DEBUG
struct VaultUnlockView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VaultUnlockView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultUnlockState(
                            biometricUnlockStatus: .available(
                                .faceID,
                                enabled: false,
                                hasValidIntegrity: false
                            )
                        )
                    )
                )
            )
        }.previewDisplayName("No Button")

        NavigationView {
            VaultUnlockView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultUnlockState(
                            biometricUnlockStatus: .available(
                                .faceID,
                                enabled: true,
                                hasValidIntegrity: true
                            )
                        )
                    )
                )
            )
        }.previewDisplayName("Face ID Button")

        NavigationView {
            VaultUnlockView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultUnlockState(
                            biometricUnlockStatus: .available(
                                .touchID,
                                enabled: true,
                                hasValidIntegrity: true
                            )
                        )
                    )
                )
            )
        }.previewDisplayName("Touch ID Button")
    }
}
#endif
