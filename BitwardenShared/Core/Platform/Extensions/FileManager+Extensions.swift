import Foundation

extension FileManager {
    /// The name of the directory that holds downloaded attachments, both at the root and for each user.
    private static let attachmentsDirectoryName = "Attachments"

    /// Returns the URL of the directory that holds the attachments downloaded by all users. Attachments
    /// are decrypted into the temporary directory so that the system can clear them.
    ///
    /// - Returns: The URL of the directory that holds the attachments for all users.
    ///
    func attachmentsRootUrl() -> URL {
        temporaryDirectory.appendingPathComponent(Self.attachmentsDirectoryName, isDirectory: true)
    }

    /// Returns a URL for saving attachments for a user.
    ///
    /// - Parameter userId: The user ID of the user that downloaded the attachments.
    /// - Returns: A URL for saving attachments for a user.
    ///
    func attachmentsUrl(for userId: String) -> URL {
        attachmentsRootUrl().appendingPathComponent(userId, isDirectory: true)
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

    /// Deletes the attachments downloaded by all users, including any left behind by older versions of
    /// the app that stored them in the application support directory.
    ///
    /// - Throws: An error if any of the attachments could not be deleted. The remaining attachments are
    ///   still deleted.
    ///
    func removeAllAttachments() throws {
        try removeAllAttachments(
            rootUrl: attachmentsRootUrl(),
            applicationSupportUrl: url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false,
            ),
        )
    }

    /// Deletes the attachments downloaded by all users from the given locations.
    ///
    /// - Parameters:
    ///   - rootUrl: The directory that holds the attachments for all users.
    ///   - applicationSupportUrl: The application support directory, which may hold legacy attachments.
    /// - Throws: An error if any of the attachments could not be deleted. The remaining attachments are
    ///   still deleted.
    ///
    func removeAllAttachments(rootUrl: URL, applicationSupportUrl: URL) throws {
        var firstError: Error?
        do {
            try removeItems(at: [rootUrl])
        } catch {
            firstError = error
        }

        do {
            try removeLegacyAttachments(applicationSupportUrl: applicationSupportUrl)
        } catch {
            firstError = firstError ?? error
        }

        if let firstError {
            throw firstError
        }
    }

    /// Deletes the attachments downloaded by a user, if there are any.
    ///
    /// - Parameter userId: The user ID of the user whose attachments should be deleted.
    /// - Throws: An error if the attachments could not be deleted.
    ///
    func removeAttachments(for userId: String) throws {
        try removeItems(at: [attachmentsUrl(for: userId)])
    }

    /// Deletes the attachments that older versions of the app stored in the application support
    /// directory, in `<userId>/Attachments` for each user.
    ///
    /// - Parameter applicationSupportUrl: The application support directory.
    /// - Throws: An error if any of the attachments could not be deleted. The remaining attachments are
    ///   still deleted.
    ///
    func removeLegacyAttachments(applicationSupportUrl: URL) throws {
        guard fileExists(atPath: applicationSupportUrl.path) else { return }
        let userDirectories = try contentsOfDirectory(
            at: applicationSupportUrl,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles],
        )
        try removeItems(at: userDirectories.map { userDirectory in
            userDirectory.appendingPathComponent(Self.attachmentsDirectoryName, isDirectory: true)
        })
    }

    /// Deletes the items at the given urls that exist. Every item is attempted, even if an earlier one
    /// fails, so that one item that can't be deleted doesn't leave the others behind. The first error is
    /// thrown once all of the items have been attempted.
    ///
    /// - Parameter urls: The urls of the items to delete.
    /// - Throws: The first error that occurred while deleting an item.
    ///
    private func removeItems(at urls: [URL]) throws {
        var firstError: Error?
        for url in urls where fileExists(atPath: url.path) {
            do {
                try removeItem(at: url)
            } catch {
                firstError = firstError ?? error
            }
        }

        if let firstError {
            throw firstError
        }
    }
}
