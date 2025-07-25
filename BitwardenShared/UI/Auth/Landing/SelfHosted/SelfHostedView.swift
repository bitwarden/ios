import BitwardenResources
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
        SectionView(Localizations.customEnvironment, contentSpacing: 8) {
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
                ),
                footer: Localizations.customEnvironmentFooter
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
                    send: SelfHostedAction.serverUrlChanged
                ),
                footer: Localizations.selfHostedEnvironmentFooter
            )
            .accessibilityIdentifier("ServerUrlEntry")
            .autocorrectionDisabled()
            .keyboardType(.URL)
            .textContentType(.URL)
            .textInputAutocapitalization(.never)
        }
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    SelfHostedView(store: Store(processor: StateProcessor(state: SelfHostedState())))
}
#endif
