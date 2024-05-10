import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension CompleteRegistrationState {
    static func fixture(
        arePasswordsVisible: Bool = false,
        isCheckDataBreachesToggleOn: Bool = false,
        passwordHintText: String = "",
        passwordText: String = "password1234",
        passwordStrengthScore: UInt8 = 3,
        userEmail: String = "email@example.com",
        retypePasswordText: String = "password1234"
    ) -> Self {
        CompleteRegistrationState(
            arePasswordsVisible: arePasswordsVisible,
            isCheckDataBreachesToggleOn: isCheckDataBreachesToggleOn,
            passwordHintText: passwordHintText,
            passwordText: passwordText,
            passwordStrengthScore: passwordStrengthScore,
            retypePasswordText: retypePasswordText,
            userEmail: userEmail
        )
    }
}
