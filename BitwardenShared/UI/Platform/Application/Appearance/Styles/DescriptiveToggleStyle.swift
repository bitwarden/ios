import SwiftUI

// MARK: - DescriptiveToggleStyle

/// A view that consists of a toggle trailed by a description.
///
struct DescriptiveToggleStyle<Content: View>: ToggleStyle {
    // MARK: Properties

    /// The toggle's description.
    @ViewBuilder let description: () -> Content

    // MARK: View

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            VStack {
                Toggle(configuration)
                    .labelsHidden()
                    .tint(Color(asset: Asset.Colors.primaryBitwarden))
            }
            .padding(.trailing, 4)

            description()

            Spacer()
        }
    }
}
