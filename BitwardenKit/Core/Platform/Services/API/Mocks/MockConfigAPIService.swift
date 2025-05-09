import BitwardenKit
import Foundation
import Networking
import TestHelpers

public class MockConfigAPIService: ConfigAPIService {
    public var clientResult: Result<HTTPResponse, Error> = .httpSuccess(testData: .validServerConfig)
    public var clientRequestCount: Int = 0

    public init() {}

    public func getConfig() async throws -> ConfigResponseModel {
        clientRequestCount += 1
        let result = try clientResult.get()
        return try ConfigResponseModel(response: result)
    }
}
