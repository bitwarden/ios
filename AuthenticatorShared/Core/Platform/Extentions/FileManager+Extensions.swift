import Foundation

extension FileManager {
    /// Returns a URL for an exported items directory.
    ///
    /// - Returns: A URL for storing an items export file.
    ///
    func exportedItemsUrl() throws -> URL {
        try url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("Exports", isDirectory: true)
    }
}
