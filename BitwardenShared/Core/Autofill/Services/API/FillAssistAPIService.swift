import Foundation

// MARK: - FillAssistAPIService

/// A protocol for an API service used to make Fill-Assist requests.
///
protocol FillAssistAPIService { // sourcery: AutoMockable
    /// Fetches the Forms Map from the map-the-web repository.
    ///
    /// - Returns: A `FormsMapResponseModel` containing form field selectors keyed by host and pathname.
    ///
    func getFormsMap() async throws -> FormsMapResponseModel

    /// Fetches the Fill-Assist manifest from the map-the-web repository.
    ///
    /// - Returns: A `FillAssistManifestResponseModel` describing available map artifacts and their versions.
    ///
    func getManifest() async throws -> FillAssistManifestResponseModel
}

// MARK: - APIService Extension

extension APIService: FillAssistAPIService {
    func getFormsMap() async throws -> FormsMapResponseModel {
        try await fillAssistService.send(FormsMapRequest())
    }

    func getManifest() async throws -> FillAssistManifestResponseModel {
        try await fillAssistService.send(FillAssistManifestRequest())
    }
}
