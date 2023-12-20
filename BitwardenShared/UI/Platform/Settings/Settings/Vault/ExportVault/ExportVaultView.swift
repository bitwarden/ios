import SwiftUI

// MARK: - ExportVaultView

/// A view that allows users to export their vault..
///
struct ExportVaultView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ExportVaultState, ExportVaultAction, ExportVaultEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            fileFormatField

            passwordField

            exportVaultButton
        }
        .scrollView()
        .navigationBar(title: Localizations.exportVault, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
    }

    // MARK: Private Views

    /// The button to export the vault.
    private var exportVaultButton: some View {
        Button {
            // TODO: BIT-449
        } label: {
            Text(Localizations.exportVault)
        }
        .buttonStyle(TertiaryButtonStyle())
    }

    /// The selector to choose the export file format.
    private var fileFormatField: some View {
        BitwardenMenuField(
            title: Localizations.fileFormat,
            options: ExportFormatType.allCases,
            selection: store.binding(
                get: \.fileFormat,
                send: ExportVaultAction.fileFormatTypeChanged
            )
        )
    }

    /// The password text field.
    private var passwordField: some View {
        BitwardenTextField(
            accessibilityIdentifier: "MasterPasswordEntry",
            title: Localizations.masterPassword,
            footer: Localizations.exportVaultMasterPasswordDescription,
            isPasswordVisible: store.binding(
                get: \.isPasswordVisible,
                send: ExportVaultAction.togglePasswordVisibility
            ),
            passwordVisibilityAccessibilityId: "PasswordVisibilityToggle",
            text: store.binding(
                get: \.passwordText,
                send: ExportVaultAction.passwordTextChanged
            )
        )
        .textFieldConfiguration(.password)
    }
}

// MARK: - Previews

#Preview {
    ExportVaultView(store: Store(processor: StateProcessor(state: ExportVaultState())))
}
