import SnapshotTesting
import SwiftUI

// MARK: - Key Window Detection

/// Returns whether the tests are running in a host application that has a key window.
///
/// Rendering from the key window (`drawHierarchyInKeyWindow`) requires a host application. Test
/// targets without one, such as `BitwardenKitSnapshotTests`, use layer rendering instead.
///
/// - Returns: `true` if a host application with a key window is available.
///
@usableFromInline
func isRunningInHostWithKeyWindow() -> Bool {
    MainActor.assumeIsolated {
        // `UIApplication.shared` isn't available without a host application, so look it up
        // dynamically, the same way swift-snapshot-testing does.
        let selector = NSSelectorFromString("sharedApplication")
        guard UIApplication.responds(to: selector),
              let application = UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
        else {
            return false
        }
        return application.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .contains { $0.isKeyWindow }
    }
}

public extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
    /// Whether snapshots are rendered from the key window by default. Rendering from the key window
    /// is required to capture effects that are drawn outside the view's layer, such as Liquid Glass.
    /// Test targets without a host application fall back to layer rendering.
    @usableFromInline internal static var defaultDrawHierarchyInKeyWindow: Bool { isRunningInHostWithKeyWindow() }

    /// The default precision for all view snapshots in this project. Defaults to `1`.
    private static var defaultPrecision: Float { 0.99 }

    /// The default perceptual precision for all view snapshots in this project. Defaults to `0.95`.
    private static var defaultPerceptualPrecision: Float { 0.95 }

    /// A default snapshot in landscape on iPhone 13, with precision 1 and perceptual precision of 0.95.
    static var defaultLandscape: Snapshotting {
        .imageWithoutAnimations(
            drawHierarchyInKeyWindow: defaultDrawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: .iPhone13(.landscape)),
            traits: UITraitCollection(userInterfaceStyle: .light),
        )
    }

    /// A default snapshot in landscape on iPhone 13, with precision 1 and perceptual precision of 0.95.
    /// This also sets the preferred content size category to AX5.
    static var defaultLandscapeAX5: Snapshotting {
        .imageWithoutAnimations(
            drawHierarchyInKeyWindow: defaultDrawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: .iPhone13(.landscape)),
            traits: UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .light),
                UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge),
            ]),
        )
    }

    /// A default snapshot in landscape on iPhone 13, with precision 1 and perceptual precision of 0.95
    /// and in dark mode.
    static var defaultLandscapeDark: Snapshotting {
        .imageWithoutAnimations(
            drawHierarchyInKeyWindow: defaultDrawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: .iPhone13(.landscape)),
            traits: UITraitCollection(userInterfaceStyle: .dark),
        )
    }

    /// A default snapshot in portrait on iPhone 13, with precision 1 and perceptual precision of 0.95.
    static var defaultPortrait: Snapshotting {
        .imageWithoutAnimations(
            drawHierarchyInKeyWindow: defaultDrawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: .iPhone13(.portrait)),
            traits: UITraitCollection(userInterfaceStyle: .light),
        )
    }

    /// A default snapshot in portrait on iPhone 13, with precision 1 and perceptual precision of 0.95.
    /// This also sets the preferred content size category to AX5.
    static var defaultPortraitAX5: Snapshotting {
        .imageWithoutAnimations(
            drawHierarchyInKeyWindow: defaultDrawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: .iPhone13(.portrait)),
            traits: UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .light),
                UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge),
            ]),
        )
    }

    /// A default snapshot in portrait on iPhone 13, with precision 1, perceptual precision of 0.95
    /// and in dark mode.
    static var defaultPortraitDark: Snapshotting {
        .imageWithoutAnimations(
            drawHierarchyInKeyWindow: defaultDrawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: .iPhone13(.portrait)),
            traits: .init(userInterfaceStyle: .dark),
        )
    }

    /// A default snapshot sized to fit the view, with precision 1 and perceptual precision of 0.95.
    static var sizeThatFits: Snapshotting {
        .imageWithoutAnimations(
            drawHierarchyInKeyWindow: defaultDrawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .sizeThatFits,
            traits: UITraitCollection(userInterfaceStyle: .light),
        )
    }

    /// A tall snapshot in portrait on iPhone 13, with precision 1, perceptual precision of 0.95 and in light mode.
    ///
    /// This snapshot has double the height of a standard iPhone 13 snapshot, and should be used when the height
    /// of a screen exceeds the height of the `defaultPortrait` snapshot.
    static var tallPortrait: Snapshotting {
        var viewImageConfig = ViewImageConfig.iPhone13(.portrait)
        viewImageConfig.size?.height *= 2
        return .imageWithoutAnimations(
            drawHierarchyInKeyWindow: defaultDrawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: viewImageConfig),
            traits: .init(userInterfaceStyle: .light),
        )
    }

    /// A tall snapshot in portrait on iPhone 13, with precision 1, perceptual precision of 0.95 and in light mode.
    ///
    /// This snapshot has triple the height of a standard iPhone 13 snapshot, and should be used when the height
    /// of a screen exceeds the height of the `defaultPortrait` snapshot.
    static var tallPortrait2: Snapshotting {
        var viewImageConfig = ViewImageConfig.iPhone13(.portrait)
        viewImageConfig.size?.height *= 3
        return .imageWithoutAnimations(
            drawHierarchyInKeyWindow: defaultDrawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: viewImageConfig),
            traits: .init(userInterfaceStyle: .light),
        )
    }

    /// A snapshot in portrait on iPhone 13, with a fixed size, precision 1, perceptual precision
    /// of 0.95 and in light mode.
    ///
    ///  - Parameter heightMultiple: Sets the height multiple of the snapshot relative to the iPhone 13 height.
    ///
    static func fixedSize(width: CGFloat = 390, height: CGFloat = 100) -> Snapshotting {
        var viewImageConfig = ViewImageConfig.iPhone13(.portrait)
        viewImageConfig.size = CGSize(width: width, height: height)
        return .imageWithoutAnimations(
            drawHierarchyInKeyWindow: defaultDrawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: viewImageConfig),
            traits: .init(userInterfaceStyle: .light),
        )
    }

    /// A default snapshot in portrait on iPhone 13, with precision 1, perceptual precision of 0.95
    /// and in light mode.
    ///
    ///  - Parameters:
    ///     - heightMultiple: Sets the height multiple of the snapshot relative to the iPhone 13 height.
    ///     - drawHierarchyInKeyWindow: If `true`, the snapshot will be taken from the key window.
    ///
    static func portrait(
        heightMultiple: CGFloat = 1,
        drawHierarchyInKeyWindow: Bool = defaultDrawHierarchyInKeyWindow,
    ) -> Snapshotting {
        var viewImageConfig = ViewImageConfig.iPhone13(.portrait)
        viewImageConfig.size?.height *= heightMultiple
        return .imageWithoutAnimations(
            drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: viewImageConfig),
            traits: .init(userInterfaceStyle: .light),
        )
    }

    /// A default snapshot in portrait on iPhone 13, with precision 1, perceptual precision of 0.95
    /// and in dark mode.
    ///
    ///  - Parameters:
    ///     - heightMultiple: Sets the height multiple of the snapshot relative to the iPhone 13 height.
    ///     - drawHierarchyInKeyWindow: If `true`, the snapshot will be taken from the key window.
    ///
    static func portraitDark(
        heightMultiple: CGFloat = 1,
        drawHierarchyInKeyWindow: Bool = defaultDrawHierarchyInKeyWindow,
    ) -> Snapshotting {
        var viewImageConfig = ViewImageConfig.iPhone13(.portrait)
        viewImageConfig.size?.height *= heightMultiple
        return .imageWithoutAnimations(
            drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: viewImageConfig),
            traits: .init(userInterfaceStyle: .dark),
        )
    }

    /// A tall snapshot in portrait on iPhone 13, with precision 1, perceptual precision of 0.95 and in light mode.
    /// Should be used when the height of a screen exceeds the height of the `defaultPortrait` with large font sizes.
    ///
    /// This also sets the preferred content size category to AX5.
    ///
    ///  - Parameters:
    ///     - heightMultiple: Sets the height multiple of the snapshot relative to the iPhone 13 height.
    ///     - drawHierarchyInKeyWindow: If `true`, the snapshot will be taken from the key window.
    ///
    static func tallPortraitAX5(
        heightMultiple: CGFloat = 4,
        drawHierarchyInKeyWindow: Bool = defaultDrawHierarchyInKeyWindow,
    ) -> Snapshotting {
        var viewImageConfig = ViewImageConfig.iPhone13(.portrait)
        viewImageConfig.size?.height *= heightMultiple
        return .imageWithoutAnimations(
            drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: viewImageConfig),
            traits: UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .light),
                UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge),
            ]),
        )
    }

    // MARK: Private

    /// Returns an image snapshot strategy that renders the view with animations disabled.
    ///
    /// Animations don't progress while a snapshot is taken from the key window, so a view that animates
    /// in (for example, by fading in from `onAppear`) would otherwise be captured in its starting state.
    ///
    private static func imageWithoutAnimations(
        drawHierarchyInKeyWindow: Bool = false,
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        layout: SwiftUISnapshotLayout = .sizeThatFits,
        traits: UITraitCollection = .init(),
    ) -> Snapshotting {
        Snapshotting<AnyView, UIImage>.image(
            drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
            precision: precision,
            perceptualPrecision: perceptualPrecision,
            layout: layout,
            traits: traits,
        )
        .pullback { view in
            AnyView(
                view.transaction { transaction in
                    // Remove explicit animations (`withAnimation`) and stop implicit animations
                    // (`.animation(_:value:)`) from adding their own.
                    transaction.animation = nil
                    transaction.disablesAnimations = true
                },
            )
        }
    }
}

public extension Snapshotting where Value == UIViewController, Format == UIImage {
    /// Whether snapshots are rendered from the key window by default. Rendering from the key window
    /// is required to capture effects that are drawn outside the view's layer, such as Liquid Glass.
    /// Test targets without a host application fall back to layer rendering.
    @usableFromInline internal static var defaultDrawHierarchyInKeyWindow: Bool { isRunningInHostWithKeyWindow() }

    /// The default precision for all view controller snapshots in this project. Defaults to `1`.
    private static var defaultPrecision: Float { 0.99 }

    /// The default perceptual precision for all view controller snapshots in this project. Defaults to `0.95`.
    private static var defaultPerceptualPrecision: Float { 0.95 }

    /// A default snapshot in landscape on iPhone 13, with precision 1 and perceptual precision of 0.95.
    static var standardImage: Snapshotting {
        .image(
            drawHierarchyInKeyWindow: defaultDrawHierarchyInKeyWindow,
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            size: ViewImageConfig.iPhone13(.portrait).size,
        )
    }
}
