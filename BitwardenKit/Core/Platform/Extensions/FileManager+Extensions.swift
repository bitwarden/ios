import Foundation

extension FileManager {
    /// Returns a URL for the directory containing flight recorder logs.
    ///
    /// - Returns: A URL for a directory to store flight recorder logs, or `nil` if the container URL is unavailable.
    ///
    func flightRecorderLogURL() throws -> URL? {
        containerURL(forSecurityApplicationGroupIdentifier: Bundle.main.groupIdentifier)?
            .appendingPathComponent("FlightRecorderLogs", isDirectory: true)
    }
}
