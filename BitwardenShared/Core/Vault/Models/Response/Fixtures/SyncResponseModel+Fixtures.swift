@testable import BitwardenShared

extension SyncResponseModel {
    static func fixture(
        ciphers: [CipherDetailsResponseModel]? = nil,
        collections: [CollectionDetailsResponseModel]? = nil,
        domains: DomainsResponseModel? = nil,
        folders: [FolderResponseModel]? = nil,
        object: String? = nil,
        policies: [PolicyResponseModel]? = nil,
        profile: ProfileResponseModel? = nil,
        sends: [SendResponseModel]? = nil
    ) -> SyncResponseModel {
        self.init(
            ciphers: ciphers,
            collections: collections,
            domains: domains,
            folders: folders,
            object: object,
            policies: policies,
            profile: profile,
            sends: sends
        )
    }
}
