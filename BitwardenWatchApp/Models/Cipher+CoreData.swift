import CoreData

extension CipherDTO {
    func toCipherEntity(moContext: NSManagedObjectContext) -> CipherEntity {
        let entity = CipherEntity(context: moContext)
        entity.id = id
        entity.name = name
        entity.userId = userId ?? "unknown"
        entity.username = login.username
        entity.totp = login.totp

        if let uris = login.uris, let encodedData = try? JSONEncoder().encode(uris) {
            entity.loginUris = String(data: encodedData, encoding: .utf8)
        }

        return entity
    }
}
