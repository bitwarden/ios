import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension StartRegistrationState {
    static func fixture(
        emailText: String = "example@email.com",
        isTermsAndPrivacyToggleOn: Bool = true,
        nameText: String = "name",
        region: RegionType = .unitedStates
    ) -> Self {
        StartRegistrationState(
            emailText: emailText,
            isTermsAndPrivacyToggleOn: isTermsAndPrivacyToggleOn,
            nameText: nameText,
            region: region
        )
    }
}
