// MARK: - NotificationType

/// An enum representing the types of push notification data the app might receive.
///
enum NotificationType: Int, Codable {
    case syncCipherUpdate = 0
    case syncCipherCreate = 1
    case syncLoginDelete = 2
    case syncFolderDelete = 3
    case syncCiphers = 4

    case syncVault = 5
    case syncOrgKeys = 6
    case syncFolderCreate = 7
    case syncFolderUpdate = 8
    case syncCipherDelete = 9
    case syncSettings = 10

    case logOut = 11

    case syncSendCreate = 12
    case syncSendUpdate = 13
    case syncSendDelete = 14

    case authRequest = 15
    case authRequestResponse = 16
}
