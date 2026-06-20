import Foundation

// MARK: - FillAssistAPIService

/// A protocol for an API service used to make Fill-Assist requests.
///
protocol FillAssistAPIService { // sourcery: AutoMockable
    /// Fetches a versioned Forms Map from the map-the-web repository.
    ///
    /// - Parameter filename: The artifact filename from the manifest (e.g. `"forms.v1.json"`).
    /// - Returns: A `FormsMapResponseModel` containing form field selectors keyed by host and pathname.
    ///
    func getFormsMap(filename: String) async throws -> FormsMapResponseModel

    /// Fetches the Fill-Assist manifest from the map-the-web repository.
    ///
    /// - Returns: A `FillAssistManifestResponseModel` describing available map artifacts and their versions.
    ///
    func getManifest() async throws -> FillAssistManifestResponseModel
}

// MARK: - APIService Extension

extension APIService: FillAssistAPIService {
    func getFormsMap(filename: String) async throws -> FormsMapResponseModel {
        let fileURL = try await fillAssistService.download(filename: filename)
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder.pascalOrSnakeCaseDecoder.decode(FormsMapResponseModel.self, from: data)
    }

    func getManifest() async throws -> FillAssistManifestResponseModel {
        let fileURL = try await fillAssistService.download(filename: "manifest.json")
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder.pascalOrSnakeCaseDecoder.decode(FillAssistManifestResponseModel.self, from: data)
    }
}
