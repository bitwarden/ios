import CoreData
import Foundation

public extension CipherEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<CipherEntity> {
        NSFetchRequest<CipherEntity>(entityName: "CipherEntity")
    }

    @NSManaged var id: String
    @NSManaged var name: String?
    @NSManaged var userId: String
    @NSManaged var totp: String?
    @NSManaged var type: NSObject?
    @NSManaged var username: String?
    @NSManaged var loginUris: String?
}

extension CipherEntity: Identifiable {
    func toCipher() -> CipherDTO {
        var loginUrisArray: [LoginUriDTO]?
        if loginUris != nil {
            loginUrisArray = try? JSONDecoder().decode([LoginUriDTO].self, from: loginUris!.data(using: .utf8)!)
        }

        return CipherDTO(
            id: id,
            login: LoginDTO(
                totp: totp,
                uris: loginUrisArray,
                username: username
            ),
            name: name,
            userId: userId
        )
    }
}
