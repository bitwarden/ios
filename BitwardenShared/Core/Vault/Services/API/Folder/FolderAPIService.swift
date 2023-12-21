import Networking

// MARK: - FolderAPIService

/// A protocol for an API service used to make folder requests.
///
protocol FolderAPIService {
    /// Add a new folder.
    ///
    /// - Parameter name: The name for the new folder.
    ///
    /// - Returns: Data returned from the `AddFolderRequest`.
    ///
    func addFolder(name: String) async throws -> FolderResponseModel
}

// MARK: - APIService

extension APIService: FolderAPIService {
    func addFolder(name: String) async throws -> FolderResponseModel {
        try await apiService.send(AddFolderRequest(name: name))
    }
}
