import Foundation

@testable import BitwardenShared

extension OrganizationUserNotificationBannerDismissal {
    static func fixture(
        revisionDate: Date? = nil,
        showAfterEveryLogin: Bool = false,
    ) -> OrganizationUserNotificationBannerDismissal {
        OrganizationUserNotificationBannerDismissal(
            revisionDate: revisionDate,
            showAfterEveryLogin: showAfterEveryLogin,
        )
    }
}
