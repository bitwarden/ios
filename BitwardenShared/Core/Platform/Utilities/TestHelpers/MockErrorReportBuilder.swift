import XCTest

@testable import BitwardenShared

class MockErrorReportBuilder: ErrorReportBuilder {
    var buildShareErrorLogCallStack: String?
    var buildShareErrorLogError: Error?
    var buildShareErrorLogReturnValue: String = "Bitwarden Error Report"

    func buildShareErrorLog(for error: Error, callStack: String) -> String {
        buildShareErrorLogCallStack = callStack
        buildShareErrorLogError = error
        return buildShareErrorLogReturnValue
    }
}
