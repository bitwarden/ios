import BitwardenResources
import SwiftUI
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
                )
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 35)
                .onAppear { isScanning = true }
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
    }
}

// MARK: - CardScannerView

/// A `UIViewControllerRepresentable` that presents a pre-warmed `DataScannerViewController`.
///
/// - `isScanning` drives `startScanning()`/`stopScanning()` via `updateUIViewController`,
///   toggled by the wrapper's `.onAppear`/`.onDisappear`.
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

    // MARK: Static methods for UIViewControllerRepresentable

    /// Stops scanning and clears the delegate when SwiftUI removes this representable from the hierarchy,
    /// releasing the AVFoundation camera session held internally by `DataScannerViewController`.
    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
        uiViewController.delegate = nil
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
        Coordinator(onLinesUpdated: onLinesUpdated)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isScanning {
            try? uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
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

        // MARK: Initialization

        init(onLinesUpdated: @escaping ([String]) -> Void) {
            self.onLinesUpdated = onLinesUpdated
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
