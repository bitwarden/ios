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
        VStack(alignment: .leading, spacing: 16) {
            rememberThisDeviceToggle

            decryptMethodButtons

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
        Toggle(isOn: store.binding(
            get: \.isRememberDeviceToggleOn,
            send: LoginDecryptionOptionsAction.toggleRememberDevice
        )) {
            VStack(alignment: .leading, spacing: 1) {
                Text(Localizations.rememberThisDevice)
                    .styleGuide(.subheadline)
                Text(Localizations.turnOffUsingPublicDevice)
                    .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                    .styleGuide(.footnote)
            }
        }
        .padding(.bottom, 24)
        .accessibilityIdentifier("RememberThisDeviceToggle")
        .toggleStyle(.bitwarden)
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
        if store.state.continueButtonEnabled {
            continueButton
        }

        if store.state.approveWithOtherDeviceEnabled {
            approveWithOtherDeviceButton
        }

        if store.state.requestAdminApprovalEnabled {
            requestAdminApprovalButton
        }

        if store.state.approveWithMasterPasswordEnabled {
            approveWithMasterPasswordButton
        }
    }

    /// The "logged in as..." text along with the not you button.
    @ViewBuilder var loggedInAs: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Localizations.loggingInAsX(
                store.state.email
            ))
            .accessibilityIdentifier("LoggingInAsLabel")
            .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

            AsyncButton(Localizations.notYou) {
                await store.perform(.notYouPressed)
            }
            .accessibilityIdentifier("NotYouButton")
            .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
        }
        .styleGuide(.footnote)
        .padding(.top, 24)
    }
}
