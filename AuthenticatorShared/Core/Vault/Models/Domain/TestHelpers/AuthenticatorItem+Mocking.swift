@testable import AuthenticatorShared

extension AuthenticatorItem {
    init(authenticatorItemView: AuthenticatorItemView) {
        self.init(
            id: authenticatorItemView.id,
            name: authenticatorItemView.name,
            totpKey: authenticatorItemView.totpKey
        )
    }
}

extension AuthenticatorItemView {
    init(authenticatorItem: AuthenticatorItem) {
        self.init(
            id: authenticatorItem.id,
            name: authenticatorItem.name,
            totpKey: authenticatorItem.totpKey
        )
    }
}
