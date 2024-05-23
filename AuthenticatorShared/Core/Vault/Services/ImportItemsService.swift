import Foundation

// MARK: - ImportItemsService

/// A service to import items from a file.
///
protocol ImportItemsService: AnyObject {
    /// Import items with a given format.
    ///
    /// - Parameters:
    ///   - data: The data to import.
    ///   - format: The format of the file to import.
    ///
    func importItems(data: Data, format: ImportFileFormat) async throws
}

extension ImportItemsService {
    /// Import items with a given format.
    ///
    /// - Parameters:
    ///   - url: The URL of the file to import.
    ///   - format: The format of the file to import.
    ///
    func importItems(url: URL, format: ImportFileFormat) async throws {
        let data = try Data(contentsOf: url)
        try await importItems(data: data, format: format)
    }
}

class DefaultImportItemsService: ImportItemsService {
    // MARK: Properties

    /// The item service.
    private let authenticatorItemRepository: AuthenticatorItemRepository

    /// The error reporter used by this service.
    private let errorReporter: ErrorReporter

    // MARK: Initilzation

    /// Initializes a new instance of a `DefaultExportItemsService`.
    ///
    /// This service handles exporting items from local storage into a file.
    ///
    /// - Parameters:
    ///   - authenticatorItemRepository: The service for storing items.
    ///   - errorReporter: The service for handling errors.
    ///
    init(
        authenticatorItemRepository: AuthenticatorItemRepository,
        errorReporter: ErrorReporter
    ) {
        self.authenticatorItemRepository = authenticatorItemRepository
        self.errorReporter = errorReporter
    }

    // MARK: Methods

    func importItems(data: Data, format: ImportFileFormat) async throws {
        let items: [AuthenticatorItemView]
        switch format {
        case .bitwardenJson:
            items = try BitwardenImporter.importItems(data: data)
        case .lastpassJson:
            items = try LastpassImporter.importItems(data: data)
        case .raivoJson:
            items = try RaivoImporter.importItems(data: data)
        case .twoFasJson:
            items = try TwoFasImporter.importItems(data: data)
        }
        try await items.asyncForEach { item in
            try await authenticatorItemRepository.addAuthenticatorItem(item)
        }
    }
}
