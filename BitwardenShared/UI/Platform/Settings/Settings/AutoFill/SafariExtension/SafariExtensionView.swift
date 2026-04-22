import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - SafariExtensionView

/// A temporary setup view for the Safari extension flow.
struct SafariExtensionView: View {
    @ObservedObject var store: Store<SafariExtensionState, SafariExtensionAction, Void>

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                Spacer()

                Text("Safari Extension")
                    .styleGuide(.title)
                    .multilineTextAlignment(.center)

                Text("Prepare Bitwarden Safari integration for save/update, generator, and page-aware fill.")
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Activate Safari Extension") {
                    store.send(.activateButtonTapped)
                }
                .buttonStyle(.secondary())

                Spacer()
            }
            .padding(.vertical, 16)
            .frame(minHeight: geometry.size.height)
            .scrollView(addVerticalPadding: false)
        }
        .navigationBar(title: "Safari Extension", titleDisplayMode: .inline)
    }
}

#Preview {
    SafariExtensionView(
        store: Store(
            processor: StateProcessor(state: SafariExtensionState()),
        ),
    )
}
