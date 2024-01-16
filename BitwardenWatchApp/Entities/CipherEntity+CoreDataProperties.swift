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
    func toCipher() -> Cipher {
        var loginUrisArray: [LoginUri]?
        if loginUris != nil {
            loginUrisArray = try? JSONDecoder().decode([LoginUri].self, from: loginUris!.data(using: .utf8)!)
        }

        return Cipher(id: id,
                      name: name,
                      userId: userId,
                      login: Login(username: username, totp: totp, uris: loginUrisArray))
    }
}
