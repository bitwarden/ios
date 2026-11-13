import BitwardenKit
import BitwardenResources
import SwiftUI
import UIKit
import VisionKit

// MARK: - CardScannerWrapperView

/// A SwiftUI view that hosts the card scanner with a navigation bar, instruction text,
/// and a Done button. This is the entry point for card scanning presented as a sheet.
///
@available(iOS 16.0, *)
struct CardScannerWrapperView: View {
    // MARK: Properties

    /// The pre-warmed scanner instance created before the sheet was presented.
    let scanner: DataScannerViewController

    /// Called with the current recognized text lines when the scanner has sufficient data
    /// or when the user explicitly completes the scan.
    let onLinesUpdated: ([String]) -> Void

    /// Drives `startScanning()`/`stopScanning()` via the SwiftUI view lifecycle.
    @SwiftUI.State private var isScanning = false

    /// Counts how many stop-then-restart cycles have been attempted this session in response to
    /// genuine scanner failures (`onScannerUnavailable`). Capped at 2 to avoid infinite loops;
    /// resets on each `.onAppear`. Foreground-triggered restarts do not count against this budget.
    @SwiftUI.State private var scannerRetryCount = 0

    /// The scanner's laid-out size, measured by a background `GeometryReader`. Passed down so that
    /// a size change, a rotation most importantly, re-derives the region of interest.
    @SwiftUI.State private var scannerViewSize: CGSize = .zero

    /// Dismisses the sheet when the scanner gives up after exhausting retries.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text(Localizations.positionYourCardInTheFrameToScanIt)
                    .styleGuide(.body)
                    .multilineTextAlignment(.center)
                    .padding(12)

                CardScannerView(
                    scanner: scanner,
                    onLinesUpdated: onLinesUpdated,
                    isScanning: $isScanning,
                    viewSize: scannerViewSize,
                    onScannerUnavailable: restartScanning,
                )
                .background {
                    // A background measures the scanner before the padding below is applied,
                    // without affecting layout.
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { scannerViewSize = proxy.size }
                            .onChange(of: proxy.size) { scannerViewSize = $0 }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 35)
                .onAppear {
                    scannerRetryCount = 0
                    isScanning = true
                }
                .onDisappear { isScanning = false }
            }
            .navigationTitle(Localizations.scanCard)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelToolbarItem {
                    dismiss()
                }
            }
        }
        .navigationViewStyle(.stack)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // `scenePhase` is driven by SwiftUI's own `Scene`/`App` lifecycle and is unreliable
            // for views hosted in a UIKit app via `UIHostingController`, so foreground transitions
            // are observed directly via `UIApplication` notifications instead.
            if isScanning {
                resumeScanningAfterForeground()
            }
        }
    }

    // MARK: Private

    /// Stops scanning, waits 300 ms for the camera to fully release, then restarts.
    /// After two retries the sheet is dismissed so the user is never left with a blank screen.
    private func restartScanning() {
        guard scannerRetryCount < 2 else {
            dismiss()
            return
        }
        scannerRetryCount += 1
        isScanning = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            isScanning = true
        }
    }

    /// Stops scanning, waits 300 ms for the camera to fully release, then restarts, in response to
    /// the app returning to the foreground. Unlike `restartScanning()`, this does not consume the
    /// failure retry budget, since a foreground transition is a routine occurrence rather than a
    /// scanner failure and would otherwise exhaust the budget after a couple of normal app switches.
    private func resumeScanningAfterForeground() {
        isScanning = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            isScanning = true
        }
    }
}

// MARK: - CardScannerView

/// A `UIViewControllerRepresentable` that presents a pre-warmed `DataScannerViewController`.
///
/// - `isScanning` drives `startScanning()`/`stopScanning()` via `updateUIViewController`,
///   toggled by the wrapper's `.onAppear`/`.onDisappear`.
/// - `viewSize` drives the region of interest, re-deriving it whenever the view is resized. Scanning
///   waits on it, so no frame is recognized before the region is in place.
///
@available(iOS 16.0, *)
struct CardScannerView: UIViewControllerRepresentable {
    // MARK: Properties

    /// The pre-warmed scanner, created before the sheet opened to reduce startup latency.
    let scanner: DataScannerViewController

    /// Called with the current recognized text lines when the scanner has sufficient data
    /// or when the user explicitly completes the scan.
    let onLinesUpdated: ([String]) -> Void

    /// When `true`, scanning is active; when `false`, scanning is stopped.
    @Binding var isScanning: Bool

    /// The scanner's laid-out size, supplied by the wrapper. Used to derive the region of interest,
    /// since the view controller's own bounds may not have been updated yet.
    let viewSize: CGSize

    /// Called when `startScanning()` throws or the scanner becomes unavailable at runtime
    /// (e.g. camera interrupted). The wrapper uses this to schedule a stop-then-restart cycle.
    var onScannerUnavailable: (() -> Void)?

    // MARK: Static methods for UIViewControllerRepresentable

    /// Stops scanning and clears the delegate when SwiftUI removes this representable from the hierarchy,
    /// releasing the AVFoundation camera session held internally by `DataScannerViewController`.
    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
        uiViewController.delegate = nil
    }

    /// Returns the region of the scanner's view that text should be recognized within.
    ///
    /// `DataScannerViewController` recognizes text across its whole view by default, so a card
    /// scanned from a screen also picks up unrelated text, such as a date in a calendar. A
    /// card-shaped region centered in the view keeps that text out of the scan. It spans most of the
    /// view's width, takes its height from the card's aspect ratio, and clamps that height to the
    /// view so a short view still yields a valid region.
    ///
    /// - Parameter bounds: The bounds of the scanner's view.
    /// - Returns: The region to recognize text within, or `nil` when `bounds` is empty and text
    ///     should be recognized across the whole view.
    ///
    static func regionOfInterest(in bounds: CGRect) -> CGRect? {
        guard !bounds.isEmpty else { return nil }
        let width = bounds.width * Constants.cardScanRegionWidthProportion
        let height = min(
            (width / Constants.cardAspectRatio) * Constants.cardScanRegionHeightTolerance,
            bounds.height,
        )
        return CGRect(
            x: bounds.midX - width / 2,
            y: bounds.midY - height / 2,
            width: width,
            height: height,
        )
    }

    // MARK: Factory

    /// Creates and configures a `DataScannerViewController` ready to scan card text.
    /// Call this before presenting the sheet so hardware initialization begins immediately.
    static func makeScanner() -> DataScannerViewController {
        DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: false,
        )
    }

    // MARK: UIViewControllerRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(onLinesUpdated: onLinesUpdated, onScannerUnavailable: onScannerUnavailable)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Assigning reconfigures a running scanner, so only assign when the region has changed.
        let region = Self.regionOfInterest(in: CGRect(origin: .zero, size: viewSize))
        if uiViewController.regionOfInterest != region {
            uiViewController.regionOfInterest = region
        }

        // Wait for a region before scanning, otherwise the first frames recognize text across the
        // whole view. The wrapper reports a size once laid out, so the wait is a single layout pass.
        guard isScanning, region != nil else {
            uiViewController.stopScanning()
            return
        }

        do {
            try uiViewController.startScanning()
        } catch {
            DispatchQueue.main.async { context.coordinator.onScannerUnavailable?() }
        }
    }
}

// MARK: - Coordinator

@available(iOS 16.0, *)
extension CardScannerView {
    /// Coordinator acting as `DataScannerViewControllerDelegate`.
    /// Accumulates recognized text lines and forwards them to the processor via `onLinesUpdated`.
    /// Parsing and sufficiency checks are handled by the processor, not here.
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        // MARK: Properties

        /// Accumulated text lines recognized so far.
        private var recognizedLines: [String] = []

        /// The scanner, set in `makeUIViewController`.
        weak var scanner: DataScannerViewController?

        let onLinesUpdated: ([String]) -> Void

        /// Forwarded from `CardScannerView.onScannerUnavailable`; called when `startScanning()`
        /// fails or the camera is interrupted at runtime.
        var onScannerUnavailable: (() -> Void)?

        // MARK: Initialization

        init(onLinesUpdated: @escaping ([String]) -> Void, onScannerUnavailable: (() -> Void)?) {
            self.onLinesUpdated = onLinesUpdated
            self.onScannerUnavailable = onScannerUnavailable
        }

        // MARK: DataScannerViewControllerDelegate

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem],
        ) {
            updateLines(from: allItems)
            notifyProcessor()
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem],
        ) {
            updateLines(from: allItems)
            notifyProcessor()
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didRemove removedItems: [RecognizedItem],
            allItems: [RecognizedItem],
        ) {
            updateLines(from: allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable,
        ) {
            onScannerUnavailable?()
        }

        // MARK: Private Helpers

        private func updateLines(from items: [RecognizedItem]) {
            recognizedLines = items.compactMap { item -> String? in
                if case let .text(textItem) = item {
                    return textItem.transcript
                }
                return nil
            }
        }

        /// Forwards the current lines to the processor on every OCR update.
        /// The processor decides whether the data is sufficient to dismiss the scanner.
        private func notifyProcessor() {
            onLinesUpdated(recognizedLines)
        }
    }
}
