import Foundation
import Testing

@testable import BitwardenShared

// MARK: - FileManagerExtensionsTests

struct FileManagerExtensionsTests {
    // MARK: Properties

    let fileManager = FileManager.default

    // MARK: Tests

    /// `attachmentsUrl(for:)` returns a directory for the user within the temporary directory.
    @Test
    func attachmentsUrl_isInTemporaryDirectoryForUser() {
        let url = fileManager.attachmentsUrl(for: "user-1")

        #expect(url.path.hasPrefix(fileManager.temporaryDirectory.path))
        #expect(url.lastPathComponent == "user-1")
        #expect(url.deletingLastPathComponent() == fileManager.attachmentsRootUrl())
    }

    /// `removeAllAttachments(rootUrl:applicationSupportUrl:)` deletes the attachments of all users from
    /// the root directory and from the legacy locations, and leaves the other application support files.
    @Test
    func removeAllAttachments_removesRootAndLegacyAttachments() throws {
        let rootUrl = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let applicationSupportUrl = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? fileManager.removeItem(at: rootUrl)
            try? fileManager.removeItem(at: applicationSupportUrl)
        }

        let rootFileUrl = rootUrl
            .appendingPathComponent("user-1", isDirectory: true)
            .appendingPathComponent("file.txt")
        try writeFile(at: rootFileUrl)

        let legacyFileUrl = applicationSupportUrl
            .appendingPathComponent("user-1", isDirectory: true)
            .appendingPathComponent("Attachments", isDirectory: true)
            .appendingPathComponent("file.txt")
        try writeFile(at: legacyFileUrl)

        let databaseUrl = applicationSupportUrl.appendingPathComponent("Bitwarden.sqlite")
        try writeFile(at: databaseUrl)

        try fileManager.removeAllAttachments(rootUrl: rootUrl, applicationSupportUrl: applicationSupportUrl)

        #expect(!fileManager.fileExists(atPath: rootUrl.path))
        #expect(!fileManager.fileExists(atPath: legacyFileUrl.deletingLastPathComponent().path))
        #expect(fileManager.fileExists(atPath: databaseUrl.path))
    }

    /// `removeAllAttachments(rootUrl:applicationSupportUrl:)` does nothing when there are no attachments.
    @Test
    func removeAllAttachments_withoutAttachments_doesNotThrow() throws {
        try fileManager.removeAllAttachments(
            rootUrl: fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            applicationSupportUrl: fileManager.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true),
        )
    }

    /// `removeAttachments(for:)` deletes the attachments of the user and leaves other users' attachments.
    @Test
    func removeAttachments_removesOnlyTheUsersAttachments() throws {
        let userId = UUID().uuidString
        let otherUserId = UUID().uuidString
        let userFileUrl = try createAttachment(for: userId)
        let otherUserFileUrl = try createAttachment(for: otherUserId)
        defer { try? fileManager.removeAttachments(for: otherUserId) }

        try fileManager.removeAttachments(for: userId)

        #expect(!fileManager.fileExists(atPath: userFileUrl.path))
        #expect(fileManager.fileExists(atPath: otherUserFileUrl.path))
    }

    /// `removeAttachments(for:)` does nothing when the user has no attachments.
    @Test
    func removeAttachments_withoutAttachments_doesNotThrow() throws {
        try fileManager.removeAttachments(for: UUID().uuidString)
    }

    /// `removeLegacyAttachments(applicationSupportUrl:)` does nothing when the directory doesn't exist.
    @Test
    func removeLegacyAttachments_missingDirectory_doesNotThrow() throws {
        let missingUrl = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)

        try fileManager.removeLegacyAttachments(applicationSupportUrl: missingUrl)
    }

    /// `removeLegacyAttachments(applicationSupportUrl:)` deletes the attachments that older versions
    /// stored for each user, and leaves the other files in the application support directory.
    @Test
    func removeLegacyAttachments_removesEachUsersAttachmentsOnly() throws {
        let applicationSupportUrl = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: applicationSupportUrl) }

        let legacyFileUrl = applicationSupportUrl
            .appendingPathComponent("user-1", isDirectory: true)
            .appendingPathComponent("Attachments", isDirectory: true)
            .appendingPathComponent("file.txt")
        try fileManager.createDirectory(
            at: legacyFileUrl.deletingLastPathComponent(),
            withIntermediateDirectories: true,
        )
        try Data("attachment".utf8).write(to: legacyFileUrl)

        let databaseUrl = applicationSupportUrl.appendingPathComponent("Bitwarden.sqlite")
        try Data("database".utf8).write(to: databaseUrl)

        try fileManager.removeLegacyAttachments(applicationSupportUrl: applicationSupportUrl)

        #expect(!fileManager.fileExists(atPath: legacyFileUrl.deletingLastPathComponent().path))
        #expect(fileManager.fileExists(atPath: databaseUrl.path))
    }

    // MARK: Private Methods

    /// Creates a downloaded attachment file for a user.
    ///
    /// - Parameter userId: The ID of the user that downloaded the attachment.
    /// - Returns: The URL of the attachment file.
    ///
    private func createAttachment(for userId: String) throws -> URL {
        let fileUrl = fileManager.attachmentsUrl(for: userId).appendingPathComponent("file.txt")
        try writeFile(at: fileUrl)
        return fileUrl
    }

    /// Writes a file, creating its parent directories if needed.
    ///
    /// - Parameter url: The url of the file to write.
    ///
    private func writeFile(at url: URL) throws {
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("attachment".utf8).write(to: url)
    }
}
