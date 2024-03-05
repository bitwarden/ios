// MARK: - LoginState

/// An object that defines the current state of a `LoginView`.
///
struct LoginState: Equatable {
    // MARK: Properties

    /// The master password provided by the user.
    var masterPassword: String = ""

    /// A flag indicating if the master password should be revealed or not.
    var isMasterPasswordRevealed: Bool = false

    /// A flag indicating if the login with device button should be displayed or not.
    var isLoginWithDeviceVisible: Bool = false

    /// The password visibility icon used in the view's text field.
    var passwordVisibleIcon: ImageAsset {
        isMasterPasswordRevealed ? Asset.Images.hidden : Asset.Images.visible
    }

    /// The server URL that is hosting the user's session.
    var serverURLString: String = ""

    /// The username provided by the user on the landing screen.
    var username: String = ""
}
