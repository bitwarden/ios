import BitwardenKit
import XCTest

public class MockErrorReportBuilder: ErrorReportBuilder {
    public var buildShareErrorLogCallStack: String?
    public var buildShareErrorLogError: Error?
    public var buildShareErrorLogReturnValue: String = "Bitwarden Error Report"

    public init() {}

    public func buildShareErrorLog(for error: Error, callStack: String) async -> String {
        buildShareErrorLogCallStack = callStack
        buildShareErrorLogError = error
        return buildShareErrorLogReturnValue
    }
}
