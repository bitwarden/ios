// MARK: - AsyncButton

import SwiftUI

/// A wrapper around SwiftUI's `Button` that used to trigger the region selector Alert
///
struct RegionSelector: View {
    // MARK: Properties

    /// The async action to perform when the user interacts with the button.
    let action: () async -> Void

    /// A binding to the toast to show.
    var regionName: String

    /// The text that is shown before the action text
    var selectorLabel: String

    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack(spacing: 4) {
                Group {
                    Text("\(selectorLabel): ")
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                        + Text(regionName).bold()
                        .foregroundColor(Asset.Colors.textInteraction.swiftUIColor)
                }
                .styleGuide(.footnote)

                Image(decorative: Asset.Images.chevronDown24)
                    .foregroundColor(Asset.Colors.iconSecondary.swiftUIColor)
            }
        }
        .accessibilityIdentifier("RegionSelectorDropdown")
    }

    // MARK: Initialization

    /// Creates a new `RegionSelector`.
    ///
    /// - Parameters:
    ///   - action: The async action to perform when the user interacts with this selector.
    ///
    init(
        selectorLabel: String,
        regionName: String,
        action: @escaping () async -> Void
    ) {
        self.action = action
        self.regionName = regionName
        self.selectorLabel = selectorLabel
    }
}
