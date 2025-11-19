@testable import BitwardenShared

extension SyncResponseModel {
    static func fixture(
        ciphers: [CipherDetailsResponseModel] = [],
        collections: [CollectionDetailsResponseModel] = [],
        domains: DomainsResponseModel? = nil,
        folders: [FolderResponseModel] = [],
        policies: [PolicyResponseModel] = [],
        profile: ProfileResponseModel? = nil,
        sends: [SendResponseModel] = [],
        userDecryption: UserDecryptionResponseModel? = nil,
    ) -> SyncResponseModel {
        self.init(
            ciphers: ciphers,
            collections: collections,
            domains: domains,
            folders: folders,
            policies: policies,
            profile: profile,
            sends: sends,
            userDecryption: userDecryption,
        )
    }
}
