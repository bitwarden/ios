import VisionKit
import XCTest

@testable import BitwardenShared

// MARK: - CardScannerViewTests

/// Tests for `CardScannerView.Coordinator`.
///
/// `CardScannerWrapperView`'s retry/foreground-resume logic is driven by SwiftUI `@State` and cannot
/// be meaningfully exercised without a live view host, so it is not covered here.
///
@available(iOS 16.0, *)
class CardScannerViewTests: BitwardenTestCase {
    // MARK: Tests

    /// `dataScanner(_:becameUnavailableWithError:)` calls `onScannerUnavailable` when the scanner
    /// reports an `unsupported` error.
    func test_becameUnavailableWithError_callsOnScannerUnavailable_unsupported() {
        var callbackInvoked = false
        let subject = CardScannerView.Coordinator(
            onLinesUpdated: { _ in },
            onScannerUnavailable: { callbackInvoked = true },
        )

        subject.dataScanner(CardScannerView.makeScanner(), becameUnavailableWithError: .unsupported)

        XCTAssertTrue(callbackInvoked)
    }

    /// `dataScanner(_:becameUnavailableWithError:)` calls `onScannerUnavailable` when the scanner
    /// reports a `cameraRestricted` error.
    func test_becameUnavailableWithError_callsOnScannerUnavailable_cameraRestricted() {
        var callbackInvoked = false
        let subject = CardScannerView.Coordinator(
            onLinesUpdated: { _ in },
            onScannerUnavailable: { callbackInvoked = true },
        )

        subject.dataScanner(CardScannerView.makeScanner(), becameUnavailableWithError: .cameraRestricted)

        XCTAssertTrue(callbackInvoked)
    }

    /// `dataScanner(_:becameUnavailableWithError:)` does not crash when `onScannerUnavailable` is nil.
    func test_becameUnavailableWithError_nilCallback_doesNotCrash() {
        let subject = CardScannerView.Coordinator(
            onLinesUpdated: { _ in },
            onScannerUnavailable: nil,
        )

        subject.dataScanner(CardScannerView.makeScanner(), becameUnavailableWithError: .unsupported)
    }
}
