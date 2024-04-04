import SwiftUI

// MARK: - ExportVaultView

/// A view that allows users to export their vault.
///
struct ExportVaultView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ExportVaultState, ExportVaultAction, ExportVaultEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            disabledExportInfo

            fileFormatField

            filePasswordFields

            masterPasswordField

            exportVaultButton
        }
        .animation(.default, value: store.state.filePasswordStrengthScore)
        .disabled(store.state.disableIndividualVaultExport)
        .scrollView()
        .navigationBar(title: Localizations.exportVault, titleDisplayMode: .inline)
        .task {
            await store.perform(.loadData)
        }
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
    }

    // MARK: Private Views

    /// An info container displayed if individual export is disabled.
    @ViewBuilder private var disabledExportInfo: some View {
        if store.state.disableIndividualVaultExport {
            InfoContainer(Localizations.disablePersonalVaultExportPolicyInEffect)
                .accessibilityIdentifier("DisablePrivateVaultPolicyLabel")
        }
    }

    /// The button to export the vault.
    private var exportVaultButton: some View {
        Button(Localizations.exportVault) {
            store.send(.exportVaultTapped)
        }
        .buttonStyle(.tertiary())
        .accessibilityIdentifier("ExportVaultButton")
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

    /// The master password text field.
    private var masterPasswordField: some View {
        BitwardenTextField(
            title: Localizations.masterPassword,
            text: store.binding(
                get: \.masterPasswordText,
                send: ExportVaultAction.masterPasswordTextChanged
            ),
            footer: Localizations.exportVaultMasterPasswordDescription,
            accessibilityIdentifier: "MasterPasswordEntry",
            passwordVisibilityAccessibilityId: "PasswordVisibilityToggle",
            isPasswordVisible: store.binding(
                get: \.isMasterPasswordVisible,
                send: ExportVaultAction.toggleMasterPasswordVisibility
            )
        )
        .textFieldConfiguration(.password)
    }
}

// MARK: - Previews

#Preview {
    ExportVaultView(store: Store(processor: StateProcessor(state: ExportVaultState())))
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
