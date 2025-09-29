import BitwardenResources
import SwiftUI

// MARK: - AppExtensionView

/// A view that has instructions and a button for activating the app extension.
///
struct AppExtensionView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AppExtensionState, AppExtensionAction, Void>

    var imageAsset: ImageAsset {
        switch (store.state.extensionActivated, store.state.extensionEnabled) {
        case (false, _):
            // Not activated
            Asset.Images.appExtensionPreview
        case (true, false):
            // Activated, not enabled
            Asset.Images.appExtensionActivate
        case (true, true):
            // Enabled
            Asset.Images.appExtensionEnabled
        }
    }

    /// The message to display in the view.
    var message: String {
        switch (store.state.extensionActivated, store.state.extensionEnabled) {
        case (false, _):
            // Not activated
            Localizations.extensionTurnOn
        case (true, false):
            // Activated, not enabled
            Localizations.extensionTapIcon
        case (true, true):
            // Enabled
            Localizations.extensionInSafari
        }
    }

    /// The title message to display in the view.
    var title: String {
        switch (store.state.extensionActivated, store.state.extensionEnabled) {
        case (false, _):
            // Not activated
            Localizations.extensionInstantAccess
        case (true, false):
            // Activated, not enabled
            Localizations.extensionAlmostDone
        case (true, true):
            // Enabled
            Localizations.extensionReady
        }
    }

    // MARK: View

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                instructionsContent

                Spacer()

                image

                Spacer()

                activateButton
            }
            .padding(.vertical, 16)
            .frame(minHeight: geometry.size.height)
            .scrollView(addVerticalPadding: false)
        }
        .navigationBar(title: Localizations.appExtension, titleDisplayMode: .inline)
    }

    // MARK: Private Views

    /// The activate button.
    private var activateButton: some View {
        Button(
            store.state.extensionEnabled
                ? Localizations.reactivateAppExtension
                : Localizations.extensionEnable
        ) {
            store.send(.activateButtonTapped)
        }
        .buttonStyle(.secondary())
    }

    /// The instruction image.
    private var image: some View {
        Image(asset: imageAsset)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 281)
            .accessibilityHidden(true)
    }

    /// The instructions text.
    private var instructionsContent: some View {
        VStack(spacing: 20) {
            instructionsTitle

            instructionsBody
        }
    }

    /// The instructions body.
    private var instructionsBody: some View {
        Text(message)
            .styleGuide(.body)
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The instructions title.
    private var instructionsTitle: some View {
        Text(title)
            .styleGuide(.title)
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Previews

#Preview("Not Activated") {
    AppExtensionView(
        store: Store(
            processor: StateProcessor(
                state: AppExtensionState(extensionActivated: false, extensionEnabled: false)
            )
        )
    )
}

#Preview("Activated, Not Enabled") {
    AppExtensionView(
        store: Store(
            processor: StateProcessor(
                state: AppExtensionState(extensionActivated: true, extensionEnabled: false)
            )
        )
    )
}

#Preview("Enabled") {
    AppExtensionView(
        store: Store(
            processor: StateProcessor(
                state: AppExtensionState(extensionActivated: true, extensionEnabled: true)
            )
        )
    )
}
