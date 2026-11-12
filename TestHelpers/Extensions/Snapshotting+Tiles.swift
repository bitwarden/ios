import SnapshotTesting
import SwiftUI

// MARK: - Tiled Key Window Snapshots

/// The tallest view, in pixels, that `UIView.drawHierarchy(in:afterScreenUpdates:)` can capture.
/// Taller views are captured as blank images, so they're captured in tiles instead.
let maxKeyWindowCaptureHeightInPixels: CGFloat = 8192

/// Returns whether a snapshot of the given configuration is too tall to capture from the key window
/// in a single pass.
///
/// - Parameter config: The configuration that determines the snapshot's size.
/// - Returns: `true` if the snapshot needs to be captured in tiles.
///
func exceedsKeyWindowCaptureLimit(_ config: ViewImageConfig) -> Bool {
    guard let height = config.size?.height else { return false }
    let scale = MainActor.assumeIsolated { keyWindowForSnapshots()?.screen.scale ?? 1 }
    return height * scale > maxKeyWindowCaptureHeightInPixels
}

extension Snapshotting where Value == AnyView, Format == UIImage {
    /// Returns a snapshot strategy for a view that's too tall to capture from the key window in a
    /// single pass. The view is laid out at its full size, captured from the key window in tiles,
    /// and the tiles are drawn into one image.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match.
    ///   - config: The device configuration that determines the snapshot's size and traits.
    ///   - traits: Additional traits to apply to the view.
    /// - Returns: A snapshot strategy that captures the view in tiles.
    ///
    static func tiledKeyWindowImage(
        precision: Float,
        perceptualPrecision: Float,
        config: ViewImageConfig,
        traits: UITraitCollection,
    ) -> Snapshotting {
        Snapshotting<UIImage, UIImage>.image(precision: precision, perceptualPrecision: perceptualPrecision)
            .pullback { view in
                MainActor.assumeIsolated {
                    renderInTiles(view: view, config: config, traits: traits)
                }
            }
    }
}

// MARK: - Private

/// Renders a view at its full configured size by capturing it from the key window in tiles that
/// each fit within the `drawHierarchy` capture limit.
///
/// The view is laid out once at its full height. Each tile is captured by moving the window's
/// bounds, rather than the view, so the view's layout and safe area don't change between tiles.
///
@MainActor
private func renderInTiles(view: AnyView, config: ViewImageConfig, traits: UITraitCollection) -> UIImage {
    guard let window = keyWindowForSnapshots() else {
        fatalError("Tiled snapshots require tests to be run in a host application")
    }
    let scale = window.screen.scale
    let size = config.size ?? window.bounds.size
    let tileHeight = min(floor(maxKeyWindowCaptureHeightInPixels / scale), size.height)
    let combinedTraits = UITraitCollection(traitsFrom: [config.traits, traits])

    let hostingController = UIHostingController(rootView: view)
    let rootViewController = UIViewController()
    rootViewController.view.backgroundColor = .clear
    rootViewController.addChild(hostingController)
    rootViewController.setOverrideTraitCollection(combinedTraits, forChild: hostingController)
    rootViewController.view.addSubview(hostingController.view)
    hostingController.didMove(toParent: rootViewController)

    let originalFrame = window.frame
    let originalRootViewController = window.rootViewController
    defer {
        hostingController.willMove(toParent: nil)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
        window.rootViewController = originalRootViewController
        window.bounds.origin = .zero
        window.frame = originalFrame
    }

    window.rootViewController = rootViewController
    window.frame.size = CGSize(width: size.width, height: tileHeight)
    // The hosting view extends past the bottom of the window. Each tile scrolls the window's
    // bounds down to the part of the view being captured.
    hostingController.view.frame = CGRect(origin: .zero, size: size)
    hostingController.view.layoutIfNeeded()

    let format = UIGraphicsImageRendererFormat(for: combinedTraits)
    format.scale = scale
    return UIGraphicsImageRenderer(size: size, format: format).image { context in
        var offset: CGFloat = 0
        while offset < size.height {
            // Keep the last tile inside the view; it overlaps the previous tile instead.
            let tileOrigin = min(offset, size.height - tileHeight)
            window.bounds.origin.y = tileOrigin
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: 0, y: tileOrigin)
            window.drawHierarchy(
                in: CGRect(origin: .zero, size: CGSize(width: size.width, height: tileHeight)),
                afterScreenUpdates: true,
            )
            context.cgContext.restoreGState()
            offset += tileHeight
        }
    }
}
