import BitwardenSdk
import Foundation

// MARK: - ExportFileType

/// An enum describing the format of the vault export file.
///
enum ExportFileType: Equatable {
    /// A `.csv` file type.
    case csv

    /// An encypted `.json` file type.
    case encryptedJson(password: String)

    /// A `.json` file type.
    case json

    /// The file extension type to use.
    var fileExtension: String {
        switch self {
        case .csv:
            "csv"
        case .encryptedJson,
             .json:
            "json"
        }
    }
}

// MARK: - ExportVaultService

/// A service to export vault contents and write them to a file.
///
protocol ExportVaultService: AnyObject {
    /// Removes any temporarily export files.
    func clearTemporaryFiles()

    /// Creates the file contents for an exported vault of a given file type.
    ///
    /// - Parameter format: The format to use for vault export.
    /// - Returns: A string representing the file content.
    ///
    func exportVaultFileContents(format: ExportFileType) async throws -> String

    /// Generates a file name for the export file based on the current date, time, and specified extension.
    /// - Parameters:
    ///   - prefix: An optional prefix to include in the file name. Defaults to nil.
    ///   - fileExtension: The file extension for the export file. Defaults to "csv".
    /// - Returns: A string representing the file name.
    func generateExportFileName(
        prefix: String?,
        extension fileExtension: String
    ) -> String

    /// Writes content to file with a provided name and returns a URL for the file.
    ///
    /// - Parameters:
    ///    - fileName: The name of the file.
    ///    - fileContent: The content of the file.
    /// - Returns: A URL for the file.
    ///
    func writeToFile(name fileName: String, content fileContent: String) throws -> URL
}

extension ExportVaultService {
    /// Export a vault with a given format.
    ///
    /// - Parameters:
    ///    - format: The format of the exported file.
    ///
    /// - Returns: A URL for the exported vault file.
    ///
    func exportVault(format: ExportFileType) async throws -> URL {
        // Export the vault in the correct file content format.
        let exportFileContents = try await exportVaultFileContents(format: format)

        // Generate the file name.
        let fileName = generateExportFileName(extension: format.fileExtension)

        // Write the content to a file with the name.
        let fileURL = try writeToFile(name: fileName, content: exportFileContents)

        return fileURL
    }

    /// Generates a file name for the export file based on the current date, time, and specified extension.
    ///
    /// - Parameter fileExtension: The file extension for the export file. Defaults to "csv".
    /// - Returns: A string representing the file name.
    ///
    func generateExportFileName(extension fileExtension: String) -> String {
        generateExportFileName(prefix: nil, extension: fileExtension)
    }
}

class DefultExportVaultService: ExportVaultService {
    // MARK: Parameters

    /// The cipher service used by this service.
    private let cipherService: CipherService

    private let clientService: ClientService

    /// The error reporter used by this service.
    private let errorReporter: ErrorReporter

    /// The folder service used by this service.
    private let folderService: FolderService

    /// The state service used by this Default Service.
    private var stateService: StateService

    /// The time provider used by this service.
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initializes a new instance of the `DefaultExportVaultService`.
    ///
    /// This service orchestrates the export of vault data by utilizing various sub-services
    ///  to fetch data, format it, and handle errors.
    ///
    /// - Parameters:
    ///   - cipherService: The service for managing ciphers.
    ///   - clientExporters: The component for formatting data into exportable files.
    ///   - errorReporter: The service for handling errors.
    ///   - folderService: The service for managing folders.
    ///   - timeProvider: The provider for current time, used in file naming and data timestamps.
    ///
    init(
        cipherService: CipherService,
        clientService: ClientService,
        errorReporter: ErrorReporter,
        folderService: FolderService,
        stateService: StateService,
        timeProvider: TimeProvider
    ) {
        self.cipherService = cipherService
        self.clientService = clientService
        self.errorReporter = errorReporter
        self.folderService = folderService
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: Methods

    func clearTemporaryFiles() {
        Task {
            do {
                let url = try FileManager.default.exportedVaultURL()
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
            } catch {
                errorReporter.log(error: error)
            }
        }
    }

    func exportVaultFileContents(format: ExportFileType) async throws -> String {
        var exportFormat: BitwardenSdk.ExportFormat
        let folders = try await folderService.fetchAllFolders()
        var ciphers = try await cipherService.fetchAllCiphers()
            .filter { $0.deletedDate == nil }
            .filter { $0.organizationId == nil }
        switch format {
        case .csv:
            exportFormat = .csv
            // Only export Login and Secure Note ciphers for CSV.
            ciphers = ciphers
                .filter { cipher in
                    cipher.type == .login || cipher.type == .secureNote
                }
        case let .encryptedJson(password):
            exportFormat = .encryptedJson(password: password)
        case .json:
            exportFormat = .json
        }

        // A string representing the file contents
        return try await clientService.clientExporters().exportVault(
            folders: folders,
            ciphers: ciphers,
            format: exportFormat
        )
    }

    func generateExportFileName(
        prefix: String?,
        extension fileExtension: String
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = dateFormatter.string(from: timeProvider.presentTime)

        let prefixString = prefix.map { "_\($0)" } ?? ""
        return "bitwarden\(prefixString)_export_\(dateString).\(fileExtension)"
    }

    func writeToFile(
        name fileName: String,
        content fileContent: String
    ) throws -> URL {
        // Get the exports directory.
        let exportsDirectoryURL = try FileManager.default.exportedVaultURL()

        // Check if the directory exists, and create it if it doesn't.
        if !FileManager.default.fileExists(atPath: exportsDirectoryURL.path) {
            try FileManager.default.createDirectory(
                at: exportsDirectoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        // Create the file URL.
        let fileURL = exportsDirectoryURL.appendingPathComponent(fileName, isDirectory: false)

        // Write the content to the file.
        try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
