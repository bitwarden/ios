import BitwardenKit
import BitwardenResources
import SwiftUI
import UniformTypeIdentifiers

// MARK: - SelfHostedView

/// A view for configuring a self-hosted environment.
///
struct SelfHostedView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<SelfHostedState, SelfHostedAction, SelfHostedEffect>

    /// Local state for the certificate alias text field in the dialog.
    @SwiftUI.State private var dialogAlias: String = ""

    /// Local state for the certificate password text field in the dialog.
    @SwiftUI.State private var dialogPassword: String = ""

    /// Local state for password visibility toggle in the dialog.
    @SwiftUI.State private var dialogShowPassword: Bool = false

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            selfHostedEnvironment
            customEnvironment
            clientCertificateSection
        }
        .textFieldConfiguration(.url)
        .navigationBar(title: Localizations.settings, titleDisplayMode: .inline)
        .scrollView()
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }

            saveToolbarItem {
                await store.perform(.saveEnvironment)
            }
        }
        .fileImporter(
            isPresented: store.binding(
                get: \.showingCertificateImporter,
                send: { _ in SelfHostedAction.dismissCertificateImporter },
            ),
            allowedContentTypes: [UTType(filenameExtension: "p12")!, UTType(filenameExtension: "pfx")!],
            onCompletion: { result in
                store.send(.certificateFileSelected(result))
            },
        )
        .alert(
            Localizations.importClientCertificate,
            isPresented: Binding(
                get: {
                    if case .setCertificateData = store.state.dialog { return true }
                    return false
                },
                set: { newValue in
                    if !newValue { store.send(.dialogDismiss) }
                },
            ),
        ) {
            TextField(Localizations.alias, text: $dialogAlias)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if dialogShowPassword {
                TextField(Localizations.password, text: $dialogPassword)
            } else {
                SecureField(Localizations.password, text: $dialogPassword)
            }
            Button(Localizations.cancel, role: .cancel) {
                dialogAlias = ""
                dialogPassword = ""
                dialogShowPassword = false
                store.send(.dialogDismiss)
            }
            Button(Localizations.submit) {
                let alias = dialogAlias
                let password = dialogPassword
                dialogAlias = ""
                dialogPassword = ""
                dialogShowPassword = false
                store.send(.certificateInfoSubmitted(alias: alias, password: password))
            }
            .disabled(dialogPassword.isEmpty)
        } message: {
            Text(Localizations.enterTheCertificatePasswordAndAlias)
        }
        .alert(
            Localizations.anErrorHasOccurred,
            isPresented: Binding(
                get: {
                    if case .error = store.state.dialog { return true }
                    return false
                },
                set: { newValue in
                    if !newValue { store.send(.dialogDismiss) }
                },
            ),
        ) {
            Button(Localizations.ok) {
                store.send(.dialogDismiss)
            }
        } message: {
            if case let .error(message) = store.state.dialog {
                Text(message)
            }
        }
        .alert(
            Localizations.replaceExistingCertificate,
            isPresented: Binding(
                get: {
                    if case .confirmOverwriteAlias = store.state.dialog { return true }
                    return false
                },
                set: { newValue in
                    if !newValue { store.send(.dialogDismiss) }
                },
            ),
        ) {
            Button(Localizations.cancel, role: .cancel) {
                store.send(.dialogDismiss)
            }
            Button(Localizations.replaceCertificate, role: .destructive) {
                store.send(.confirmOverwriteCertificate)
            }
        } message: {
            if case let .confirmOverwriteAlias(alias, _, _) = store.state.dialog {
                Text(Localizations.aCertificateWithTheAliasAlreadyExistsDescriptionLong(alias))
            }
        }
    }

    // MARK: Private views

    /// The custom environment section.
    private var customEnvironment: some View {
        SectionView(Localizations.customEnvironment, contentSpacing: 8) {
            BitwardenTextField(
                title: Localizations.webVaultUrl,
                text: store.binding(
                    get: \.webVaultServerUrl,
                    send: SelfHostedAction.webVaultUrlChanged,
                ),
            )
            .accessibilityIdentifier("WebVaultUrlEntry")

            BitwardenTextField(
                title: Localizations.apiUrl,
                text: store.binding(
                    get: \.apiServerUrl,
                    send: SelfHostedAction.apiUrlChanged,
                ),
            )
            .accessibilityIdentifier("ApiUrlEntry")

            BitwardenTextField(
                title: Localizations.identityUrl,
                text: store.binding(
                    get: \.identityServerUrl,
                    send: SelfHostedAction.identityUrlChanged,
                ),
            )
            .accessibilityIdentifier("IdentityUrlEntry")

            BitwardenTextField(
                title: Localizations.iconsUrl,
                text: store.binding(
                    get: \.iconsServerUrl,
                    send: SelfHostedAction.iconsUrlChanged,
                ),
                footer: Localizations.customEnvironmentFooter,
            )
            .accessibilityIdentifier("IconsUrlEntry")
        }
    }

    /// The self-hosted environment section.
    private var selfHostedEnvironment: some View {
        SectionView(Localizations.selfHostedEnvironment) {
            BitwardenTextField(
                title: Localizations.serverUrl,
                text: store.binding(
                    get: \.serverUrl,
                    send: SelfHostedAction.serverUrlChanged,
                ),
                footer: Localizations.selfHostedEnvironmentFooter,
            )
            .accessibilityIdentifier("ServerUrlEntry")
            .autocorrectionDisabled()
            .keyboardType(.URL)
            .textContentType(.URL)
            .textInputAutocapitalization(.never)
        }
    }

    /// The client certificate (mTLS) section.
    private var clientCertificateSection: some View {
        SectionView(Localizations.clientCertificateMtls, contentSpacing: 8) {
            BitwardenTextField(
                title: Localizations.certificateAlias,
                text: .constant(store.state.keyAlias),
                footer: Localizations.certificateUsedForClientAuthentication,
            )
            .accessibilityIdentifier("KeyAliasEntry")
            .disabled(true)

            Button(Localizations.importCertificate) {
                store.send(.importCertificateTapped)
            }
            .accessibilityIdentifier("ImportCertificateButton")
            .buttonStyle(.primary())

            if !store.state.keyAlias.isEmpty {
                Button(Localizations.removeCertificate) {
                    store.send(.removeCertificateTapped)
                }
                .accessibilityIdentifier("RemoveCertificateButton")
                .buttonStyle(.secondary(isDestructive: true))
            }
        }
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    SelfHostedView(store: Store(processor: StateProcessor(state: SelfHostedState())))
}
#endif
