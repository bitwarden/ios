import CoreData
import Foundation

enum DecoderConfigurationError: Error {
    case missingManagedObjectContext
}

@objc(CipherEntity)
public class CipherEntity: NSManagedObject, Codable {
    enum CodingKeys: CodingKey {
        case id
        case name
        case username
        case totp
        case loginUris
        case userId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(userId, forKey: .userId)
        try container.encode(username, forKey: .username)
        try container.encode(totp, forKey: .totp)
        try container.encode(loginUris, forKey: .loginUris)
    }

    public required convenience init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }

        self.init(context: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String?.self, forKey: .name)
        userId = try container.decode(String.self, forKey: .userId)
        username = try container.decode(String?.self, forKey: .username)
        totp = try container.decode(String?.self, forKey: .totp)
        loginUris = try container.decode(String?.self, forKey: .loginUris)
    }
}

extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}
