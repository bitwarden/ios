// swiftlint:disable:this file_name
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenKit

final class StyleGuideFontTests: BitwardenTestCase {
    // MARK: Properties

    /// The fonts to display, paired with their names.
    private let fonts: [(name: String, style: StyleGuideFont)] = [
        ("Huge Title", .hugeTitle),
        ("Large Title", .largeTitle),
        ("Title", .title),
        ("Title 2", .title2),
        ("Title 3", .title3),
        ("Headline", .headline),
        ("Body", .body),
        ("Body Monospaced", .bodyMonospaced),
        ("Callout", .callout),
        ("Subheadline", .subheadline),
        ("Footnote", .footnote),
        ("Caption 1", .caption1),
        ("Caption 2", .caption2),
        ("Caption 2 Monospaced", .caption2Monospaced),
    ]

    // MARK: Tests

    /// Test a snapshot of the StyleGuideFonts.
    @MainActor
    func test_snapshot_styleGuideFont() {
        for view in snapshotViews() {
            assertSnapshots(of: view, as: [.defaultPortrait])
        }
    }

    /// Test a snapshot of the StyleGuideFonts with large text.
    @MainActor
    func test_snapshot_styleGuideFont_largeText() {
        for view in snapshotViews() {
            assertSnapshots(of: view, as: [.defaultPortraitAX5])
        }
    }

    // MARK: Private

    /// Returns a view comparing each font in its standard style with the given weight and italic style.
    @MainActor
    private func fontComparison(weight: SwiftUI.Font.Weight, isItalic: Bool) -> some View {
        HStack {
            VStack(alignment: .trailing, spacing: 8) {
                ForEach(fonts, id: \.name) { font in
                    Text(font.name)
                        .styleGuide(font.style)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(fonts, id: \.name) { font in
                    Text(font.name)
                        .styleGuide(font.style, weight: weight, isItalic: isItalic)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    /// Returns the views to snapshot: font comparisons and sample views using style guide fonts.
    @MainActor
    private func snapshotViews() -> [AnyView] {
        [
            AnyView(fontComparison(weight: .semibold, isItalic: false)),
            AnyView(fontComparison(weight: .regular, isItalic: true)),
            AnyView(fontComparison(weight: .semibold, isItalic: true)),
            AnyView(sampleViews()),
        ]
    }

    /// Returns sample views that use style guide fonts.
    @MainActor
    private func sampleViews() -> some View {
        VStack(alignment: .leading) {
            Button("Sample Button", action: {})
                .buttonStyle(.primary())
                .styleGuide(.callout)
            Toggle("Toggle", isOn: .constant(true))
                .toggleStyle(.bitwarden)
            Group {
                Text(Localizations.important + ": ")
                    .bold() +
                    Text(Localizations.bitwardenCannotResetALostOrForgottenMasterPassword)
            }
            .styleGuide(.footnote)
            .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
        }
        .background(Color(.systemGroupedBackground))
    }
}
