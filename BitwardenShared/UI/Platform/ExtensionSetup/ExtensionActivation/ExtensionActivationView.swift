import SwiftUI

// MARK: - ExtensionActivationView

/// A view that confirms the user enabled and set up an app extension.
///
struct ExtensionActivationView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<
        ExtensionActivationState,
        ExtensionActivationAction,
        ExtensionActivationEffect
    >

    /// An action that opens URLs.
    @Environment(\.openURL) private var openURL

    // MARK: View

    var body: some View {
        Group {
            if store.state.showLegacyView {
                legacyContent
            } else {
                content
            }
        }
        .scrollView()
        .navigationTitle(store.state.navigationBarTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.perform(.appeared)
        }
    }

    // MARK: Private Views

    /// The main content of the view.
    @ViewBuilder private var content: some View {
        VStack(spacing: 0) {
            PageHeaderView(
                image: Asset.Images.autofillIllustration,
                title: Localizations.youreAllSet,
                message: Localizations.autoFillActivatedDescriptionLong
            )
            .padding(.top, 40)

            Button(Localizations.continueToBitwarden) {
                openURL(ExternalLinksConstants.appDeepLink)
            }
            .buttonStyle(.primary())
            .padding(.top, 40)

            Button(Localizations.backToSettings) {
                store.send(.cancelTapped)
            }
            .buttonStyle(.transparent)
            .padding(.top, 12)
        }
    }

    /// The legacy view for this screen kept intact to support both versions.
    @ViewBuilder private var legacyContent: some View {
        VStack(spacing: 64) {
            VStack(spacing: 20) {
                Text(store.state.title)
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    .styleGuide(.title3)

                Text(store.state.message)
                    .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                    .styleGuide(.body)
            }
            .multilineTextAlignment(.center)

            image
        }
        .toolbar {
            cancelToolbarItem {
                store.send(.cancelTapped)
            }
        }
    }

    /// The image to display in the view.
    @ViewBuilder private var image: some View {
        switch store.state.extensionType {
        case .appExtension:
            Image(decorative: Asset.Images.bwLogo)
                .resizable()
                .frame(width: 70, height: 70)
                .padding(16)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Asset.Colors.strokeDivider.swiftUIColor, lineWidth: 1.5)
                }
        case .autofillExtension:
            Image(decorative: Asset.Images.check)
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Autofill Extension") {
    NavigationView {
        ExtensionActivationView(
            store: Store(
                processor: StateProcessor(
                    state: ExtensionActivationState(
                        extensionType: .autofillExtension,
                        isNativeCreateAccountFeatureFlagEnabled: true
                    )
                )
            )
        )
    }
}

#Preview("App Extension") {
    NavigationView {
        ExtensionActivationView(
            store: Store(
                processor: StateProcessor(
                    state: ExtensionActivationState(
                        extensionType: .appExtension
                    )
                )
            )
        )
    }
}
#endif
