import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

final class ButtonStylesTests: BitwardenTestCase {
    // MARK: Types

    /// A view that displays all of the button styles for snapshotting.
    struct ButtonStyles: View {
        var body: some View {
            HStack(alignment: .top, spacing: 20) {
                VStack {
                    Group {
                        titleView("Primary")

                        Button("Enabled") {}
                        Button("Disabled") {}
                            .disabled(true)
                    }
                    .buttonStyle(.primary())
                }

                VStack {
                    Group {
                        titleView("Primary Destructive")

                        Button("Enabled") {}
                        Button("Disabled") {}
                            .disabled(true)
                    }
                    .buttonStyle(.primary(isDestructive: true))
                }

                VStack {
                    titleView("Secondary")

                    Button("Enabled") {}
                    Button("Disabled") {}
                        .disabled(true)
                }
                .buttonStyle(.secondary())

                VStack {
                    titleView("Borderless")

                    Button("Enabled") {}
                    Button("Disabled") {}
                        .disabled(true)
                }
                .buttonStyle(.bitwardenBorderless)
                .padding(.vertical, 14)

                VStack {
                    titleView("Field Label Icon")

                    Button {} label: {
                        Label("Options", image: Asset.Images.cog16.swiftUIImage)
                    }
                    Button {} label: {
                        Label("Options", image: Asset.Images.cog16.swiftUIImage)
                    }
                    .disabled(true)
                }
                .buttonStyle(.fieldLabelIcon)

                VStack {
                    titleView("Circle (FAB)")

                    Button {} label: {
                        Asset.Images.cog24.swiftUIImage
                    }
                    Button {} label: {
                        Asset.Images.cog24.swiftUIImage
                    }
                    .disabled(true)
                }
                .buttonStyle(CircleButtonStyle(diameter: 50))
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
        }

        func titleView(_ title: String) -> some View {
            Text(title)
                .styleGuide(.title3, weight: .bold)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
        }
    }

    // MARK: Tests

    /// Render a snapshot of the app's button styles.
    func test_snapshot_buttonStyles() {
        let subject = ButtonStyles()
        assertSnapshot(of: subject, as: .fixedSize(width: 1000, height: 300))
    }
}
