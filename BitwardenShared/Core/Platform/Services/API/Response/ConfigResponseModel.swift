import Foundation
import Networking

// MARK: - ConfigResponseModel

/// API response model for the configuration request.
///
struct ConfigResponseModel: Equatable, JSONResponse {
    // MARK: Properties

    let version: String
    
    let gitHash: String
    
    let server: ThirdPartyConfigResponseModel?

    let environment: EnvironmentServerConfigResponse?

    let featureStates: [String: AnyCodable]
}

struct ThirdPartyConfigResponseModel: Equatable, JSONResponse {
    let name: String

    let url: String
}

struct EnvironmentServerConfigResponse: Equatable, JSONResponse {
    let cloudRegion: String
    let vault: String
    let api: String
    let identity: String
    let notifications: String
    let sso: String
}
