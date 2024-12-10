// swiftlint:disable:this file_name

import BitwardenSdk

/// Temporary protocol of `ClientExportersProtocol` until the SDK PR gets merged and is available for CI
/// https://github.com/bitwarden/sdk-internal/pull/32
protocol ClientExportersServiceTemp: AnyObject {
    /// Exports ciphers with an account in Credential Exchange flow.
    func exportCxf(account: BitwardenSdkAccount, ciphers: [BitwardenSdk.Cipher]) throws -> String

    /// Exports organization vault in a given format.
    func exportOrganizationVault(collections: [Collection], ciphers: [Cipher], format: ExportFormat) throws -> String

    /// Exports vault with a given format.
    func exportVault(folders: [Folder], ciphers: [Cipher], format: ExportFormat) throws -> String

    /// Imports ciphers in Credential Exchange flow.
    func importCxf(payload: String) throws -> [BitwardenSdk.Cipher]
}

/// Mocking the responses of the export CXP flow until the SDK PR gets merged.
extension ClientExporters: ClientExportersServiceTemp {
    func exportCxf(account: BitwardenSdkAccount, ciphers: [BitwardenSdk.Cipher]) throws -> String {
        """
        {"items":[{"modifiedAt":1732226366,"creationAt":1732226366,"title":"GitHub","credentials":[{"urls":["github.com"],"password":{"id":"RTEzRDEwQjctRTdCQy00QTI3LTgwNDAtRjgxMzNBOTMxMjhC","fieldType":"concealed-string","value":"adsfasf"},"type":"basic-auth","username":{"fieldType":"string","id":"NTlBMUFBNUYtODE5My00QUIzLThGRjYtOEFCRUQ5MUQxNUZG","value":"TestCXP1"}}],"id":"MjZDQzQwQTQtQUZDQS00NEIzLUEwNjAtMUMyNUUzNTc1RTZB","type":"login"},{"type":"login","modifiedAt":1732226380,"id":"NEMzOTY4MTItRTMxMi00NUExLUE4NDYtRUFENEZDMTkyMDJC","creationAt":1732226380,"title":"Google","credentials":[{"urls":["google.com"],"type":"basic-auth","username":{"id":"MTdCOUI5NTUtM0FGOC00RDYzLUEwN0UtQjJFMjk1MTM1NDlC","fieldType":"string","value":"TestCXPGoogle"},"password":{"fieldType":"concealed-string","value":"1o23j1po3ij1o","id":"QTU2NDVDMTktMTgzQy00OEJELUI4NTMtNzg4NjYzRDk2NzI1"}}]}],"id":"RDQxRjU3QTYtM0NFNi00MTI5LUI0MkUtNUZBOUY0NkU3QTFD","collections":[],"email":"","userName":""}
        """ // swiftlint:disable:previous line_length
    }

    func importCxf(payload: String) throws -> [BitwardenSdk.Cipher] {
        [.fixture(), .fixture()]
    }
}

/// A temporary SDK Account to be used when exporting CXP.
public struct BitwardenSdkAccount {
    let id: String
    let email: String
    let name: String?
}
