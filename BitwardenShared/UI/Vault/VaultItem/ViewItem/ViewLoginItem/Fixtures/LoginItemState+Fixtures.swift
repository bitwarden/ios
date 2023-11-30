import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension LoginItemState {
    static func fixture(
        cipher: CipherView = .loginFixture(),
        editState: EditState = .view,
        isPasswordVisible: Bool = false,
        properties: VaultCipherItemProperties = .fixture()
    ) -> LoginItemState {
        var state = LoginItemState(cipherView: .loginFixture())!
        state.cipher = cipher
        state.editState = editState
        state.isPasswordVisible = isPasswordVisible
        state.properties = properties
        return state
    }
}

extension VaultCipherItemProperties {
    static func fixture(
        customFields: [CustomFieldState] = [],
        folder: String = "",
        isFavoriteOn: Bool = false,
        isMasterPasswordRePromptOn: Bool = false,
        name: String = "",
        notes: String = "",
        password: String = "",
        passwordUpdatedDate: Date? = nil,
        type: BitwardenShared.CipherType = .login,
        updatedDate: Date = Date(),
        uris: [LoginUriView] = [],
        username: String = ""
    ) -> VaultCipherItemProperties {
        VaultCipherItemProperties(
            customFields: customFields,
            folder: folder,
            isFavoriteOn: isFavoriteOn,
            isMasterPasswordRePromptOn: isMasterPasswordRePromptOn,
            name: name,
            notes: notes,
            password: password,
            type: type,
            updatedDate: updatedDate,
            uris: uris,
            username: username
        )
    }
}
