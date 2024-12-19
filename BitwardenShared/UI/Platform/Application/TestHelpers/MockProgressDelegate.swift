@testable import BitwardenShared

class MockProgressDelegate: ProgressDelegate {
    var progressReports: [Double] = []

    func report(progress: Double) {
        self.progressReports.append(progress)
    }
}
