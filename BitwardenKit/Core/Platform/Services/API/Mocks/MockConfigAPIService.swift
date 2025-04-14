import BitwardenKit
import Foundation
import Networking
import TestHelpers

public class MockConfigAPIService: ConfigAPIService {
    public var getConfigResult: Result<ConfigResponseModel, Error> =
        Result<HTTPResponse, Error>
            .httpSuccess(testData: .validServerConfig)
            .map { try! ConfigResponseModel(response: $0) } // swiftlint:disable:this force_try

    public func getConfig() async throws -> ConfigResponseModel {
        try getConfigResult.get()
    }
}
