/// API model for cipher permissions.
///
struct CipherPermissionsModel: Codable, Equatable {
    /// Whether `delete` permission is active.
    let delete: Bool

    /// Whether `restore` permission is acive.
    let restore: Bool
}
