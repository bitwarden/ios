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

    /// Delete a folder.
    ///
    /// - Parameter id: The ID of the folder to delete.
    ///
    /// - Returns: An `EmptyResponse`.
    ///
    func deleteFolder(withID id: String) async throws -> EmptyResponse

    /// Edit an existing folder.
    ///
    /// - Parameters:
    ///   - id: The ID of the folder to edit.
    ///   - name: The new name of the folder.
    ///
    /// - Returns: Data returned from the `EditFolderRequest`.
    ///
    func editFolder(withID id: String, name: String) async throws -> FolderResponseModel

    /// Retrieves an existing folder.
    ///
    /// - Parameter id: The id of the folder to retrieve.
    ///
    func getFolder(withId id: String) async throws -> FolderResponseModel
}

// MARK: - APIService

extension APIService: FolderAPIService {
    func addFolder(name: String) async throws -> FolderResponseModel {
        try await apiService.send(AddFolderRequest(name: name))
    }

    func deleteFolder(withID id: String) async throws -> EmptyResponse {
        try await apiService.send(DeleteFolderRequest(id: id))
    }

    func editFolder(withID id: String, name: String) async throws -> FolderResponseModel {
        try await apiService.send(EditFolderRequest(id: id, name: name))
    }

    func getFolder(withId id: String) async throws -> FolderResponseModel {
        try await apiService.send(GetFolderRequest(folderId: id))
    }
}
