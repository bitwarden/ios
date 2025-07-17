import BitwardenResources
import SnapshotTesting
import SwiftUI
import TestHelpers
import XCTest

@testable import BitwardenShared

final class CircularProgressShapeTests: BitwardenTestCase {
    // MARK: Tests

    func test_snapshot_progress() {
        let stack = HStack {
            CircularProgressShape(
                progress: 0.75,
                clockwise: true
            )
            .stroke(lineWidth: 3)
            .foregroundColor(SharedAsset.Colors.iconSecondary.swiftUIColor)
            .frame(width: 30, height: 30)
            CircularProgressShape(
                progress: 0.4,
                clockwise: false
            )
            .stroke(lineWidth: 3)
            .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
            .frame(width: 30, height: 30)
            CircularProgressShape(
                progress: 0.1,
                clockwise: true
            )
            .stroke(lineWidth: 3)
            .foregroundColor(.red)
            .frame(width: 30, height: 30)
            CircularProgressShape(
                progress: 0.95,
                clockwise: false
            )
            .stroke(lineWidth: 3)
            .foregroundColor(.green)
            .frame(width: 30, height: 30)
        }

        assertSnapshot(of: stack, as: .portrait(heightMultiple: 0.1))
    }
}
