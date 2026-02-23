import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - ExportFileType

/// An enum describing the format of the vault export file.
///
enum ExportFileType: Equatable {
    /// A `.csv` file type.
    case csv

    /// An encrypted `.json` file type.
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
    /// - Parameters:
    ///   - format: The format of the exported file.
    ///   - includeArchivedItems: Whether to include archived items in the export.
    /// - Returns: A string representing the file content.
    ///
    func exportVaultFileContents(format: ExportFileType, includeArchivedItems: Bool) async throws -> String

    /// Fetches all the ciphers to export for the current user.
    ///
    /// - Parameters:
    ///   - includeArchivedItems: Whether to include archived items in the export.
    /// - Returns: The ciphers to export belonging to the current user.
    ///
    func fetchAllCiphersToExport(includeArchivedItems: Bool) async throws -> [Cipher]

    /// Generates a file name for the export file based on the current date, time, and specified extension.
    /// - Parameters:
    ///   - prefix: An optional prefix to include in the file name. Defaults to nil.
    ///   - fileExtension: The file extension for the export file. Defaults to "csv".
    /// - Returns: A string representing the file name.
    func generateExportFileName(
        prefix: String?,
        extension fileExtension: String,
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
    ///    - restrictedTypes: An array of `CipherType` that should be excluded from the export.
    ///
    /// - Returns: A URL for the exported vault file.
    ///
    func exportVault(format: ExportFileType) async throws -> URL {
        // Export the vault in the correct file content format.
        let exportFileContents = try await exportVaultFileContents(
            format: format,
            includeArchivedItems: true,
        )

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

class DefaultExportVaultService: ExportVaultService {
    // MARK: Parameters

    /// The cipher service used by this service.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service to get server-specified configuration.
    private let configService: ConfigService

    /// The error reporter used by this service.
    private let errorReporter: ErrorReporter

    /// The folder service used by this service.
    private let folderService: FolderService

    /// The service used by the application to manage account state.
    private var stateService: StateService

    /// The time provider used by this service.
    private let timeProvider: TimeProvider

    /// The service used by the application to manage the policy.
    private let policyService: PolicyService

    // MARK: Initialization

    /// Initializes a new instance of the `DefaultExportVaultService`.
    ///
    /// This service orchestrates the export of vault data by utilizing various sub-services
    ///  to fetch data, format it, and handle errors.
    ///
    /// - Parameters:
    ///   - cipherService: The service for managing ciphers.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - configService: The service to get server-specified configuration.
    ///   - errorReporter: The service for handling errors.
    ///   - folderService: The service for managing folders.
    ///   - policyService: The service used by the application to manage the policy.
    ///   - stateService: The service used by the application to manage account state.
    ///   - timeProvider: The provider for current time, used in file naming and data timestamps.
    ///
    init(
        cipherService: CipherService,
        clientService: ClientService,
        configService: ConfigService,
        errorReporter: ErrorReporter,
        folderService: FolderService,
        policyService: PolicyService,
        stateService: StateService,
        timeProvider: TimeProvider,
    ) {
        self.cipherService = cipherService
        self.clientService = clientService
        self.configService = configService
        self.errorReporter = errorReporter
        self.folderService = folderService
        self.stateService = stateService
        self.timeProvider = timeProvider
        self.policyService = policyService
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

    func exportVaultFileContents(format: ExportFileType, includeArchivedItems: Bool) async throws -> String {
        var exportFormat: BitwardenSdk.ExportFormat
        let folders = try await folderService.fetchAllFolders()
        var ciphers = try await fetchAllCiphersToExport(includeArchivedItems: includeArchivedItems)

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
        return try await clientService.exporters().exportVault(
            folders: folders,
            ciphers: ciphers,
            format: exportFormat,
        )
    }

    func fetchAllCiphersToExport(includeArchivedItems: Bool) async throws -> [Cipher] {
        let restrictedTypes = await policyService.getRestrictedItemCipherTypes()
        let archiveItemsFeatureFlagEnabled: Bool = await configService.getFeatureFlag(.archiveVaultItems)

        return try await cipherService.fetchAllCiphers().filter { cipher in
            // Always exclude deleted items
            if cipher.deletedDate != nil {
                return false
            }

            // Handle archived items based on includeArchivedItems parameter
            if cipher.archivedDate != nil, !includeArchivedItems, archiveItemsFeatureFlagEnabled {
                return false
            }

            // Apply organization and restricted type filters
            return cipher.organizationId == nil
                && !restrictedTypes.contains(BitwardenShared.CipherType(type: cipher.type))
        }
    }

    func generateExportFileName(
        prefix: String?,
        extension fileExtension: String,
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = dateFormatter.string(from: timeProvider.presentTime)

        let prefixString = prefix.map { "_\($0)" } ?? ""
        return "bitwarden\(prefixString)_export_\(dateString).\(fileExtension)"
    }

    func writeToFile(
        name fileName: String,
        content fileContent: String,
    ) throws -> URL {
        // Get the exports directory.
        let exportsDirectoryURL = try FileManager.default.exportedVaultURL()

        // Check if the directory exists, and create it if it doesn't.
        if !FileManager.default.fileExists(atPath: exportsDirectoryURL.path) {
            try FileManager.default.createDirectory(
                at: exportsDirectoryURL,
                withIntermediateDirectories: true,
                attributes: nil,
            )
        }

        // Create the file URL.
        let fileURL = exportsDirectoryURL.appendingPathComponent(fileName, isDirectory: false)

        // Write the content to the file.
        try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
