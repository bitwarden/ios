import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension CreateAccountState {
    static func fixture(
        arePasswordsVisible: Bool = false,
        emailText: String = "email@example.com",
        isCheckDataBreachesToggleOn: Bool = false,
        isTermsAndPrivacyToggleOn: Bool = true,
        passwordHintText: String = "",
        passwordText: String = "password1234",
        passwordStrengthScore: UInt8 = 3,
        retypePasswordText: String = "password1234"
    ) -> Self {
        CreateAccountState(
            arePasswordsVisible: arePasswordsVisible,
            emailText: emailText,
            isCheckDataBreachesToggleOn: isCheckDataBreachesToggleOn,
            isTermsAndPrivacyToggleOn: isTermsAndPrivacyToggleOn,
            passwordHintText: passwordHintText,
            passwordText: passwordText,
            passwordStrengthScore: passwordStrengthScore,
            retypePasswordText: retypePasswordText
        )
    }
}
