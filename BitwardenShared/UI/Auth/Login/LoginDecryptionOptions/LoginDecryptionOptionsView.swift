import BitwardenResources
import SwiftUI

// MARK: - LoginDecryptionOptionsView

/// A view that allows users to trust their device and decrypt their vault
/// with master password, another device or through admin approval
///
struct LoginDecryptionOptionsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<
        LoginDecryptionOptionsState,
        LoginDecryptionOptionsAction,
        LoginDecryptionOptionsEffect
    >
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            rememberThisDeviceToggle

            VStack(spacing: 12) {
                decryptMethodButtons
            }

            loggedInAs
        }
        .scrollView()
        .navigationBar(title: Localizations.loggingIn, titleDisplayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .task {
            await store.perform(.loadLoginDecryptionOptions)
        }
    }

    // MARK: Private Views

    /// Toggle to remember the device
    private var rememberThisDeviceToggle: some View {
        BitwardenToggle(
            Localizations.rememberThisDevice,
            isOn: store.binding(
                get: \.isRememberDeviceToggleOn,
                send: LoginDecryptionOptionsAction.toggleRememberDevice
            )
        ) {
            Text(Localizations.turnOffUsingPublicDevice)
                .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
                .styleGuide(.footnote)
        }
        .accessibilityIdentifier("RememberThisDeviceToggle")
        .contentBlock()
    }

    /// Continue button that will create a JIT user
    private var continueButton: some View {
        AsyncButton(Localizations.continue) {
            await store.perform(.continuePressed)
        }
        .buttonStyle(.primary())
        .accessibilityIdentifier("ContinueButton")
    }

    /// Button to approve with other device
    private var approveWithOtherDeviceButton: some View {
        AsyncButton(Localizations.approveWithMyOtherDevice) {
            await store.perform(.approveWithOtherDevicePressed)
        }
        .buttonStyle(.primary())
        .accessibilityIdentifier("ApproveWithOtherDeviceButton")
    }

    /// Button to request admin approval
    private var requestAdminApprovalButton: some View {
        AsyncButton(Localizations.requestAdminApproval) {
            await store.perform(.requestAdminApprovalPressed)
        }
        .buttonStyle(.secondary())
        .accessibilityIdentifier("RequestAdminApprovalButton")
    }

    /// Button to approve with master password
    private var approveWithMasterPasswordButton: some View {
        AsyncButton(Localizations.approveWithMasterPassword) {
            await store.perform(.approveWithMasterPasswordPressed)
        }
        .buttonStyle(.secondary())
        .accessibilityIdentifier("ApproveWithMasterPasswordButton")
    }

    /// Show decryption method buttons based on user configurations
    @ViewBuilder var decryptMethodButtons: some View {
        if store.state.shouldShowContinueButton {
            continueButton
        }

        if store.state.shouldShowApproveWithOtherDeviceButton {
            approveWithOtherDeviceButton
        }

        if store.state.shouldShowAdminApprovalButton {
            requestAdminApprovalButton
        }

        if store.state.shouldShowApproveMasterPasswordButton {
            approveWithMasterPasswordButton
        }
    }

    /// The "logged in as..." text along with the not you button.
    @ViewBuilder var loggedInAs: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(Localizations.loggingInAsX(
                store.state.email
            ))
            .accessibilityIdentifier("LoggingInAsLabel")
            .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
            .multilineTextAlignment(.center)

            AsyncButton(Localizations.notYou) {
                await store.perform(.notYouPressed)
            }
            .accessibilityIdentifier("NotYouButton")
            .foregroundColor(SharedAsset.Colors.textInteraction.swiftUIColor)
        }
        .styleGuide(.footnote)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        LoginDecryptionOptionsView(store: Store(processor: StateProcessor(
            state: LoginDecryptionOptionsState(
                shouldShowContinueButton: true,
                email: "user@example.com",
                shouldShowAdminApprovalButton: true
            )
        )))
    }
}
#endif
