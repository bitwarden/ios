// swiftlint:disable:this file_name

import BitwardenKit
import Networking
import Security

extension APIService: ConfigAPIService {
    func getConfig() async throws -> ConfigResponseModel {
        let isAuthenticated = try? await stateService.isAuthenticated()
        guard isAuthenticated == true else {
            return try await apiUnauthenticatedService.send(ConfigRequest())
        }
        do {
            return try await apiService.send(ConfigRequest())
        } catch KeychainServiceError.osStatusError(errSecItemNotFound),
                KeychainServiceError.keyNotFound {
            // The access token was removed between the isAuthenticated check and the
            // actual request (e.g., logout during a background config refresh).
            // Fall back to the unauthenticated endpoint.
            return try await apiUnauthenticatedService.send(ConfigRequest())
        }
    }
}
