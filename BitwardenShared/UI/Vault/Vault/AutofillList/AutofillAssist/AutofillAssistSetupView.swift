import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - AutofillAssistSetupView

/// A view that allows the user to configure URL-based autofill assist field mappings.
///
struct AutofillAssistSetupView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<
        AutofillAssistSetupState,
        AutofillAssistSetupAction,
        AutofillAssistSetupEffect,
    >

    // MARK: View

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    urlField

                    usernameFieldPicker

                    passwordFieldPicker
                }
                .padding(16)
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea())
            .navigationBar(title: Localizations.addAutofillAssist, titleDisplayMode: .inline)
            .toolbar {
                cancelToolbarItem {
                    store.send(.cancelTapped)
                }

                saveToolbarItem {
                    await store.perform(.saveTapped)
                }
            }
            .toast(store.binding(
                get: \.toast,
                send: AutofillAssistSetupAction.toastShown,
            ))
        }
    }

    // MARK: Private Views

    /// The URL text field.
    private var urlField: some View {
        BitwardenTextField(
            title: Localizations.autofillAssistSetupPageUrl,
            text: store.binding(
                get: \.url,
                send: AutofillAssistSetupAction.urlChanged,
            ),
            accessibilityIdentifier: "AutofillAssistUrlEntry",
        )
        .textFieldConfiguration(.url)
    }

    /// The username field picker.
    private var usernameFieldPicker: some View {
        fieldPicker(
            title: Localizations.autofillAssistSetupUsernameField,
            selection: store.binding(
                get: \.usernameFieldOpId,
                send: AutofillAssistSetupAction.usernameFieldChanged,
            ),
            accessibilityIdentifier: "AutofillAssistUsernameFieldPicker",
        )
    }

    /// The password field picker.
    private var passwordFieldPicker: some View {
        fieldPicker(
            title: Localizations.autofillAssistSetupPasswordField,
            selection: store.binding(
                get: \.passwordFieldOpId,
                send: AutofillAssistSetupAction.passwordFieldChanged,
            ),
            accessibilityIdentifier: "AutofillAssistPasswordFieldPicker",
        )
    }

    /// Creates a picker for selecting a page field.
    ///
    /// - Parameters:
    ///   - title: The title for the picker.
    ///   - selection: The binding for the selected opId.
    ///   - accessibilityIdentifier: The accessibility identifier.
    ///
    private func fieldPicker(
        title: String,
        selection: Binding<String?>,
        accessibilityIdentifier: String,
    ) -> some View {
        BitwardenField(title: title) {
            Picker(
                title,
                selection: selection,
            ) {
                Text(Localizations.autofillAssistNone).tag(nil as String?)
                ForEach(store.state.pageFields) { field in
                    Text(field.displayLabel).tag(field.opId as String?)
                }
            }
            .accessibilityIdentifier(accessibilityIdentifier)
        }
    }
}
