// swiftlint:disable:this file_name

import BitwardenKit
import Networking

extension APIService: ConfigAPIService {
    func getConfig() async throws -> ConfigResponseModel {
        let isAuthenticated = try? await stateService.isAuthenticated()
        guard isAuthenticated == true else {
            return try await apiUnauthenticatedService.send(ConfigRequest())
        }
        return try await apiService.send(ConfigRequest())
    }
}
