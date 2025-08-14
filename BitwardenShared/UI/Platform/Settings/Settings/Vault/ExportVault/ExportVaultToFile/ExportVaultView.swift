import BitwardenResources
import SwiftUI

// MARK: - ExportVaultView

/// A view that allows users to export their vault to a file.
///
struct ExportVaultView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ExportVaultState, ExportVaultAction, ExportVaultEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            disabledExportInfo

            fileFormatField

            filePasswordFields

            masterPasswordField
        }
        .animation(.default, value: store.state.filePasswordStrengthScore)
        .disabled(store.state.disableIndividualVaultExport)
        .scrollView()
        .navigationBar(title: Localizations.exportVault, titleDisplayMode: .inline)
        .task {
            await store.perform(.loadData)
        }
        .toast(store.binding(
            get: \.toast,
            send: ExportVaultAction.toastShown
        ))
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }

            ToolbarItem(placement: .topBarTrailing) {
                primaryActionToolbarButton(Localizations.export) {
                    Task { await store.perform(.exportVaultTapped) }
                }
                .accessibilityIdentifier("ExportVaultButton")
                .disabled(store.state.disableIndividualVaultExport)
            }
        }
    }

    // MARK: Private Views

    /// An info container displayed if individual export is disabled.
    @ViewBuilder private var disabledExportInfo: some View {
        if store.state.disableIndividualVaultExport {
            InfoContainer(Localizations.disablePersonalVaultExportPolicyInEffect)
                .padding(.bottom, 8)
                .accessibilityIdentifier("DisablePrivateVaultPolicyLabel")
        }
    }

    /// The selector to choose the export file format.
    private var fileFormatField: some View {
        BitwardenMenuField(
            title: Localizations.fileFormat,
            accessibilityIdentifier: "FileFormatPicker",
            options: ExportFormatType.allCases,
            selection: store.binding(
                get: \.fileFormat,
                send: ExportVaultAction.fileFormatTypeChanged
            )
        )
    }

    /// The file password text fields for a JSON encrypted export.
    @ViewBuilder private var filePasswordFields: some View {
        if store.state.fileFormat == .jsonEncrypted {
            BitwardenTextField(
                title: Localizations.filePassword,
                text: store.binding(
                    get: \.filePasswordText,
                    send: ExportVaultAction.filePasswordTextChanged
                ),
                footer: Localizations.filePasswordDescription,
                accessibilityIdentifier: "FilePasswordEntry",
                passwordVisibilityAccessibilityId: "FilePasswordVisibilityToggle",
                isPasswordVisible: store.binding(
                    get: \.isFilePasswordVisible,
                    send: ExportVaultAction.toggleFilePasswordVisibility
                )
            )
            .textFieldConfiguration(.password)

            PasswordStrengthIndicator(
                passwordStrengthScore: store.state.filePasswordStrengthScore
            )

            BitwardenTextField(
                title: Localizations.confirmFilePassword,
                text: store.binding(
                    get: \.filePasswordConfirmationText,
                    send: ExportVaultAction.filePasswordConfirmationTextChanged
                ),
                accessibilityIdentifier: "FilePasswordEntry",
                passwordVisibilityAccessibilityId: "FilePasswordVisibilityToggle",
                isPasswordVisible: store.binding(
                    get: \.isFilePasswordVisible,
                    send: ExportVaultAction.toggleFilePasswordVisibility
                )
            )
            .textFieldConfiguration(.password)
        }
    }

    /// The master password/OTP text field.
    @ViewBuilder private var masterPasswordField: some View {
        if !store.state.hasMasterPassword {
            VStack(alignment: .leading, spacing: 8) {
                Text(Localizations.sendVerificationCodeToEmail)
                    .styleGuide(.subheadline, weight: .semibold)
                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)

                AsyncButton(Localizations.sendCode) {
                    await store.perform(.sendCodeTapped)
                }
                .buttonStyle(.secondary())
                .accessibilityIdentifier("SendTOTPCodeButton")
                .disabled(store.state.isSendCodeButtonDisabled)
            }
        }

        BitwardenTextField(
            title: store.state.masterPasswordOrOtpTitle,
            text: store.binding(
                get: \.masterPasswordOrOtpText,
                send: ExportVaultAction.masterPasswordOrOtpTextChanged
            ),
            footer: store.state.masterPasswordOrOtpFooter,
            accessibilityIdentifier: "MasterPasswordEntry",
            passwordVisibilityAccessibilityId: "PasswordVisibilityToggle",
            isPasswordVisible: store.binding(
                get: \.isMasterPasswordOrOtpVisible,
                send: ExportVaultAction.toggleMasterPasswordOrOtpVisibility
            )
        )
        .textFieldConfiguration(.password)
    }
}

// MARK: - Previews

#Preview("Export Vault") {
    ExportVaultView(store: Store(processor: StateProcessor(state: ExportVaultState())))
}

#Preview("Export Vault without Master Password") {
    ExportVaultView(store: Store(processor: StateProcessor(state: ExportVaultState(hasMasterPassword: false))))
}

#Preview("Disabled Export") {
    ExportVaultView(
        store: Store(
            processor: StateProcessor(
                state: ExportVaultState(disableIndividualVaultExport: true)
            )
        )
    )
}
