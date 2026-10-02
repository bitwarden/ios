import VisionKit
import XCTest

@testable import BitwardenShared

// MARK: - CardScannerViewTests

/// Tests for `CardScannerView` and its `Coordinator`.
///
/// `CardScannerWrapperView`'s retry/foreground-resume logic and its `GeometryReader` size measurement
/// need a live view host, so they are not covered here. Neither is `updateUIViewController`, which
/// needs a representable `Context` that a test cannot construct.
///
@available(iOS 16.0, *)
class CardScannerViewTests: BitwardenTestCase {
    // MARK: Tests

    /// `dataScanner(_:becameUnavailableWithError:)` calls `onScannerUnavailable` when the scanner
    /// reports an `unsupported` error.
    @MainActor
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
    @MainActor
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
    @MainActor
    func test_becameUnavailableWithError_nilCallback_doesNotCrash() {
        let subject = CardScannerView.Coordinator(
            onLinesUpdated: { _ in },
            onScannerUnavailable: nil,
        )

        subject.dataScanner(CardScannerView.makeScanner(), becameUnavailableWithError: .unsupported)
    }

    /// `regionOfInterest(in:)` returns a card-shaped region centered in the bounds, spanning 96% of
    /// their width with a height derived from the card's aspect ratio.
    @MainActor
    func test_regionOfInterest_centersCardShapedRegionWithinBounds() throws {
        let region = try XCTUnwrap(CardScannerView.regionOfInterest(in: CGRect(x: 0, y: 0, width: 400, height: 800)))

        XCTAssertEqual(region.minX, 8, accuracy: 0.001)
        XCTAssertEqual(region.minY, 242.6, accuracy: 0.001)
        XCTAssertEqual(region.width, 384, accuracy: 0.001)
        XCTAssertEqual(region.height, 314.799, accuracy: 0.001)
    }

    /// `regionOfInterest(in:)` centers the region on the bounds it is given rather than assuming an
    /// origin of zero.
    @MainActor
    func test_regionOfInterest_nonZeroOrigin_centersOnBounds() throws {
        let region = try XCTUnwrap(CardScannerView.regionOfInterest(in: CGRect(x: 20, y: 50, width: 400, height: 800)))

        XCTAssertEqual(region.minX, 28, accuracy: 0.001)
        XCTAssertEqual(region.minY, 292.6, accuracy: 0.001)
        XCTAssertEqual(region.width, 384, accuracy: 0.001)
        XCTAssertEqual(region.height, 314.799, accuracy: 0.001)
    }

    /// `regionOfInterest(in:)` clamps the region's height to bounds too short to contain a
    /// card-shaped region.
    @MainActor
    func test_regionOfInterest_boundsShorterThanCard_clampsHeight() throws {
        let region = try XCTUnwrap(CardScannerView.regionOfInterest(in: CGRect(x: 0, y: 0, width: 400, height: 200)))

        XCTAssertEqual(region.minX, 8, accuracy: 0.001)
        XCTAssertEqual(region.minY, 0, accuracy: 0.001)
        XCTAssertEqual(region.width, 384, accuracy: 0.001)
        XCTAssertEqual(region.height, 200, accuracy: 0.001)
    }

    /// `regionOfInterest(in:)` returns `nil` for empty bounds, so no region is applied while the
    /// view is still being laid out.
    @MainActor
    func test_regionOfInterest_emptyBounds_returnsNil() {
        XCTAssertNil(CardScannerView.regionOfInterest(in: .zero))
        XCTAssertNil(CardScannerView.regionOfInterest(in: CGRect(x: 0, y: 0, width: 400, height: 0)))
        XCTAssertNil(CardScannerView.regionOfInterest(in: CGRect(x: 0, y: 0, width: 0, height: 800)))
    }
}
