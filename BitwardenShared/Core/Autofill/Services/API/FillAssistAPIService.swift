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
}

// MARK: - APIService Extension

extension APIService: FillAssistAPIService {
    func getFormsMap() async throws -> FormsMapResponseModel {
        try await mapTheWebService.send(FormsMapRequest())
    }
}
