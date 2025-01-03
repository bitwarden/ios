@testable import BitwardenShared

class MockProgressDelegate: ProgressDelegate {
    var progressReports: [Double] = []

    func report(progress: Double) {
        progressReports.append(progress)
    }
}
