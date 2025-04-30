/// A protocol for an object that handles logging app messages.
///
public protocol BitwardenLogger {
    /// Logs a message.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: The file that called the log method.
    ///   - line: The line number in the file that called the log method.
    ///
    func log(_ message: String, file: String, line: UInt)
}

public extension BitwardenLogger {
    /// Logs a message.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: The file that called the log method.
    ///   - line: The line number in the file that called the log method.
    ///
    func log(_ message: String, file: String = #file, line: UInt = #line) {
        log(message, file: file, line: line)
    }
}
