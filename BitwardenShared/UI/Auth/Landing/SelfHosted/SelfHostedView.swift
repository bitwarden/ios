import SwiftUI

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
        section(
            header: Localizations.customEnvironment,
            footer: Localizations.customEnvironmentFooter
        ) {
            VStack(spacing: 16) {
                BitwardenTextField(
                    title: Localizations.webVaultUrl,
                    text: store.binding(
                        get: \.webVaultServerUrl,
                        send: SelfHostedAction.webVaultUrlChanged
                    )
                )
                .accessibilityIdentifier("WebVaultUrlEntry")

                BitwardenTextField(
                    title: Localizations.apiUrl,
                    text: store.binding(
                        get: \.apiServerUrl,
                        send: SelfHostedAction.apiUrlChanged
                    )
                )
                .accessibilityIdentifier("ApiUrlEntry")

                BitwardenTextField(
                    title: Localizations.identityUrl,
                    text: store.binding(
                        get: \.identityServerUrl,
                        send: SelfHostedAction.identityUrlChanged
                    )
                )
                .accessibilityIdentifier("IdentityUrlEntry")

                BitwardenTextField(
                    title: Localizations.iconsUrl,
                    text: store.binding(
                        get: \.iconsServerUrl,
                        send: SelfHostedAction.iconsUrlChanged
                    )
                )
                .accessibilityIdentifier("IconsUrlEntry")
            }
        }
        .padding(.top, 8)
    }

    /// The self-hosted environment section.
    private var selfHostedEnvironment: some View {
        section(
            header: Localizations.selfHostedEnvironment,
            footer: Localizations.selfHostedEnvironmentFooter
        ) {
            BitwardenTextField(
                title: Localizations.serverUrl,
                text: store.binding(
                    get: \.serverUrl,
                    send: SelfHostedAction.serverUrlChanged
                ),
                placeholder: "ex. https://bitwarden.company.com"
            )
            .accessibilityIdentifier("ServerUrlEntry")
            .autocorrectionDisabled()
            .keyboardType(.URL)
            .textContentType(.URL)
            .textInputAutocapitalization(.never)
        }
    }

    /// A section within the view containing a header, footer, and content.
    ///
    /// - Parameters:
    ///   - header: The section's header.
    ///   - footer: The section's footer.
    ///   - content: The section's content.
    ///
    /// - Returns: A section used within the view.
    ///
    private func section(
        header: String,
        footer: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .styleGuide(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                .textCase(.uppercase)
                .padding(.bottom, 4)

            content()

            Text(footer)
                .styleGuide(.subheadline)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
        }
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    SelfHostedView(store: Store(processor: StateProcessor(state: SelfHostedState())))
}
#endif
