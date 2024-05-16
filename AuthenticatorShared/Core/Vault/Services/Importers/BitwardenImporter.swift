import Foundation

class BitwardenImporter {
    static func importItems(data: Data) throws -> [AuthenticatorItemView] {
        let decoder = JSONDecoder()
        let vaultLike = try decoder.decode(VaultLike.self, from: data)
        let cipherLikes = vaultLike.items
        return cipherLikes.map { cipherLike in
            AuthenticatorItemView(
                favorite: cipherLike.favorite,
                id: cipherLike.id,
                name: cipherLike.name,
                totpKey: cipherLike.login?.totp,
                username: cipherLike.login?.username
            )
        }
    }
}
