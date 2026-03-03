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

    /// The client certificate section.
    private var clientCertificateSection: some View {
        SectionView("Client Certificate") {
            if store.state.clientCertificateConfiguration.isEnabled,
               let subject = store.state.clientCertificateConfiguration.subject,
               let issuer = store.state.clientCertificateConfiguration.issuer,
               let expirationDate = store.state.clientCertificateConfiguration.expirationDate {
                // Display certificate info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Certificate Subject:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(subject)
                        .font(.body)

                    Text("Certificate Issuer:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(issuer)
                        .font(.body)

                    Text("Expires:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(expirationDate, style: .date)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

                Button("Remove Certificate") {
                    store.send(.removeCertificate)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            } else {
                Button("Import Certificate") {
                    store.send(.importCertificateTapped)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .fileImporter(
            isPresented: store.binding(
                get: \.showingCertificateImporter,
                send: { _ in SelfHostedAction.dismissCertificateImporter }
            ),
            allowedContentTypes: [UTType(filenameExtension: "p12")!, UTType(filenameExtension: "pfx")!],
            onCompletion: { result in
                store.send(.certificateFileSelected(result))
            }
        )
        .sheet(
            isPresented: store.binding(
                get: \.showingPasswordPrompt,
                send: { _ in SelfHostedAction.dismissPasswordPrompt }
            )
        ) {
            certificatePasswordPrompt
        }
    }

    /// The certificate password prompt sheet.
    private var certificatePasswordPrompt: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "lock.doc")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                    Text("Certificate Password")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("This certificate is password-protected. Please enter the password to continue.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                VStack(spacing: 16) {
                    SecureField(
                        "Password",
                        text: store.binding(
                            get: \.certificatePassword,
                            send: SelfHostedAction.certificatePasswordChanged
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit {
                        if !store.state.certificatePassword.isEmpty {
                            store.send(.confirmCertificatePassword)
                        }
                    }

                    Button("Import Certificate") {
                        store.send(.confirmCertificatePassword)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.state.certificatePassword.isEmpty)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Enter Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        store.send(.dismissPasswordPrompt)
                    }
                }
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
