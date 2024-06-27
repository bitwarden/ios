import Foundation

public enum EventType: Int, Codable {
    case userLoggedIn = 1000
    case userChangedPassword = 1001
    case userUpdated2fa = 1002
    case userDisabled2fa = 1003
    case userRecovered2fa = 1004
    case userFailedLogIn = 1005
    case userFailedLogIn2fa = 1006
    case userClientExportedVault = 1007

    case cipherCreated = 1100
    case cipherUpdated = 1101
    case cipherDeleted = 1102
    case cipherAttachmentCreated = 1103
    case cipherAttachmentDeleted = 1104
    case cipherShared = 1105
    case cipherUpdatedCollections = 1106
    case cipherClientViewed = 1107
    case cipherClientToggledPasswordVisible = 1108
    case cipherClientToggledHiddenFieldVisible = 1109
    case cipherClientToggledCardCodeVisible = 1110
    case cipherClientCopiedPassword = 1111
    case cipherClientCopiedHiddenField = 1112
    case cipherClientCopiedCardCode = 1113
    case cipherClientAutofilled = 1114
    case cipherSoftDeleted = 1115
    case cipherRestored = 1116
    case cipherClientToggledCardNumberVisible = 1117

    case collectionCreated = 1300
    case collectionUpdated = 1301
    case collectionDeleted = 1302

    case groupCreated = 1400
    case groupUpdated = 1401
    case groupDeleted = 1402

    case organizationUserInvited = 1500
    case organizationUserConfirmed = 1501
    case organizationUserUpdated = 1502
    case organizationUserRemoved = 1503
    case organizationUserUpdatedGroups = 1504

    case organizationUpdated = 1600
    case organizationPurgedVault = 1601
    case organizationClientExportedVault = 1602
}
