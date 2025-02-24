@testable import AuthenticatorShared

extension AuthenticatorItem {
    init(authenticatorItemView: AuthenticatorItemView) {
        self.init(
            favorite: authenticatorItemView.favorite,
            id: authenticatorItemView.id,
            name: authenticatorItemView.name,
            totpKey: authenticatorItemView.totpKey,
            username: authenticatorItemView.username
        )
    }
}

extension AuthenticatorItemView {
    init(authenticatorItem: AuthenticatorItem) {
        self.init(
            favorite: authenticatorItem.favorite,
            id: authenticatorItem.id,
            name: authenticatorItem.name,
            totpKey: authenticatorItem.totpKey,
            username: authenticatorItem.username
        )
    }
}
