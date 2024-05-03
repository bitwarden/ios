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
    func importItems(data: Data, format: ImportFileType) async throws
}

extension ImportItemsService {
    /// Import items with a given format.
    ///
    /// - Parameters:
    ///   - url: The URL of the file to import.
    ///   - format: The format of the file to import.
    ///
    func importItems(url: URL, format: ImportFileType) async throws {
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

    func importItems(data: Data, format: ImportFileType) async throws {
        let items: [CipherLike]
        switch format {
        case .json:
            items = try importJson(data)
        }
        try await items.asyncForEach { cipherLike in
            let item = AuthenticatorItemView(
                favorite: cipherLike.favorite,
                id: cipherLike.id,
                name: cipherLike.name,
                totpKey: cipherLike.login?.totp,
                username: cipherLike.login?.username
            )
            try await authenticatorItemRepository.addAuthenticatorItem(item)
        }
    }

    // MARK: Private Methods

    private func importJson(_ data: Data) throws -> [CipherLike] {
        let decoder = JSONDecoder()
        let vaultLike = try decoder.decode(VaultLike.self, from: data)
        return vaultLike.items
    }
}
