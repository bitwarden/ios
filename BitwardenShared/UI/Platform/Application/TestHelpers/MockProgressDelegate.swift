@testable import BitwardenShared

class MockProgressDelegate: ProgressDelegate {
    var progress = 0.0

    func report(progress: Double) {
        self.progress = progress
    }
}
