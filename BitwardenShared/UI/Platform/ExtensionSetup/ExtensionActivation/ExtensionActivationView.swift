import BitwardenResources
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
        Void
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
    }

    // MARK: Private Views

    /// The main content of the view.
    @ViewBuilder private var content: some View {
        VStack(spacing: 0) {
            IllustratedMessageView(
                image: Asset.Images.autofill,
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
            .buttonStyle(.secondary())
            .padding(.top, 12)
        }
    }

    /// The legacy view for this screen kept intact to support both versions.
    @ViewBuilder private var legacyContent: some View {
        VStack(spacing: 64) {
            VStack(spacing: 20) {
                Text(store.state.title)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .styleGuide(.title3)

                Text(store.state.message)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
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
            Image(decorative: Asset.Images.shield24)
                .resizable()
                .frame(width: 70, height: 70)
                .padding(16)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(SharedAsset.Colors.strokeDivider.swiftUIColor, lineWidth: 1.5)
                }
        case .autofillExtension:
            Image(decorative: Asset.Images.check24)
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
                        extensionType: .autofillExtension
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
