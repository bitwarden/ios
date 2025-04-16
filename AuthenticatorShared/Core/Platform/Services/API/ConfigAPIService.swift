// swiftlint:disable:this file_name

import BitwardenKit
import Networking

extension APIService: ConfigAPIService {
    func getConfig() async throws -> ConfigResponseModel {
        return try await apiUnauthenticatedService.send(ConfigRequest())
    }
}
