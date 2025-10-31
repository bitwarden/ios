import Foundation

// MARK: - FileManagerProtocol

/// A protocol for an object that is used to perform filesystem tasks.
///
public protocol FileManagerProtocol: AnyObject {
    /// Appends the given data to the file at the specified URL.
    ///
    /// - Parameters:
    ///   - data: The data to append to the file.
    ///   - url: A file URL to a file for which the data should be appended to.
    ///
    func append(_ data: Data, to url: URL) throws

    /// Returns the file system attributes for a file at the specified path.
    ///
    /// - Parameter atPath: A path to a file to get the attributes for.
    /// - Returns: A dictionary of attributes of the file.
    ///
    func attributesOfItem(atPath: String) throws -> [FileAttributeKey: Any]

    /// Creates a directory at the specified URL.
    ///
    /// - Parameters:
    ///   - url: A file URL that specifies the directory to create.
    ///   - createIntermediates: Whether any nonexistent parent directories should be created when
    ///     creating the directory.
    ///
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws

    /// Removes the file or directory at the specified URL.
    ///
    /// - Parameter url: A URL to the file or directory to remove.
    ///
    func removeItem(at url: URL) throws

    /// Sets whether the file should be excluded from backups.
    ///
    /// - Parameters:
    ///   - value: `true` if the file should be excluded from backups, or `false` otherwise.
    ///   - url: The URL for the file to set whether it should be excluded from backups.
    ///
    func setIsExcludedFromBackup(_ value: Bool, to url: URL) throws

    /// Writes the given data to the file at the specified URL.
    ///
    /// - Parameters:
    ///   - data: The data to write to the file.
    ///   - url: A URL to a file that the data should be written to.
    ///
    func write(_ data: Data, to url: URL) throws
}

// MARK: - FileManager + FileManagerProtocol

extension FileManager: FileManagerProtocol {
    public func append(_ data: Data, to url: URL) throws {
        let handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
        try handle.close()
    }

    public func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        try createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories, attributes: nil)
    }

    public func setIsExcludedFromBackup(_ value: Bool, to url: URL) throws {
        try url.setIsExcludedFromBackup(value)
    }

    public func write(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }
}
