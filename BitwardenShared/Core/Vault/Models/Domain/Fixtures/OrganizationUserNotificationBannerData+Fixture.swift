import Foundation

@testable import BitwardenShared

extension OrganizationUserNotificationBannerData {
    static func fixture(
        buttonText: String? = "I understand",
        description: String = "Scheduled maintenance on March 11 from 9-11 PM.",
        headerText: String? = "Upcoming Maintenance",
        revisionDate: Date? = nil,
        showAfterEveryLogin: Bool = false,
    ) -> OrganizationUserNotificationBannerData {
        OrganizationUserNotificationBannerData(
            buttonText: buttonText,
            description: description,
            headerText: headerText,
            revisionDate: revisionDate,
            showAfterEveryLogin: showAfterEveryLogin,
        )
    }
}
