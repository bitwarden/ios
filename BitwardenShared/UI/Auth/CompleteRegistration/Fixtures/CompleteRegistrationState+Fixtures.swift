import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension CompleteRegistrationState {
    static func fixture(
        arePasswordsVisible: Bool = false,
        emailVerificationToken: String = "emailVerificationToken",
        isCheckDataBreachesToggleOn: Bool = false,
        passwordHintText: String = "",
        passwordText: String = "password1234",
        passwordStrengthScore: UInt8 = 3,
        userEmail: String = "email@example.com",
        retypePasswordText: String = "password1234"
    ) -> Self {
        CompleteRegistrationState(
            arePasswordsVisible: arePasswordsVisible,
            emailVerificationToken: emailVerificationToken,
            isCheckDataBreachesToggleOn: isCheckDataBreachesToggleOn,
            passwordHintText: passwordHintText,
            passwordText: passwordText,
            passwordStrengthScore: passwordStrengthScore,
            retypePasswordText: retypePasswordText,
            userEmail: userEmail
        )
    }
}
