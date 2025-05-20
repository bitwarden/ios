@testable import BitwardenKit

public class MockBitwardenLogger: BitwardenLogger {
    public var logs = [String]()

    public init() {}

    public func log(_ message: String, file: String, line: UInt) {
        logs.append(message)
    }
}
