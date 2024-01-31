import Foundation

extension FileManager {
    /// Returns a URL for saving attachments for a user.
    ///
    /// - Parameter userId: The user ID of the user that downloaded the attachments.
    /// - Returns: A URL for saving attachments for a user.
    ///
    func attachmentsUrl(for userId: String) throws -> URL {
        try url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent(userId, isDirectory: true)
        .appendingPathComponent("Attachments", isDirectory: true)
    }
}
