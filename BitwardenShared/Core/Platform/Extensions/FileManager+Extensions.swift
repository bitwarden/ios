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
            create: true,
        )
        .appendingPathComponent(userId, isDirectory: true)
        .appendingPathComponent("Attachments", isDirectory: true)
    }

    /// Returns a URL for the encrypted Fill Assist rules file for a user.
    ///
    /// - Parameter userId: The user ID of the active account.
    /// - Returns: A URL for the user's encrypted Fill Assist rules file.
    ///
    func fillAssistRulesURL(for userId: String) throws -> URL {
        try url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true,
        )
        .appendingPathComponent("FillAssistRules", isDirectory: true)
        .appendingPathComponent("\(userId).bin")
    }

    /// Returns a URL for an exported vault directory.
    ///
    /// - Returns: A URL for storing a vault export file.
    ///
    func exportedVaultURL() throws -> URL {
        try url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true,
        )
        .appendingPathComponent("Exports", isDirectory: true)
    }
}
