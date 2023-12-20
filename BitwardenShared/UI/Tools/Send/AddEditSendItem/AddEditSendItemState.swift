import Foundation

// MARK: - AddEditSendItemState

/// An object that defines the current state of a `AddEditSendItemView`.
///
struct AddEditSendItemState: Equatable {
    /// The custom deletion date.
    var customDeletionDate = Date.midnightOneWeekFromToday() ?? Date()

    /// The custom expiration date.
    var customExpirationDate = Date.midnightOneWeekFromToday() ?? Date()

    /// The deletion date for this item.
    var deletionDate: SendDeletionDateType = .sevenDays

    /// The expiration date for this item.
    var expirationDate: SendExpirationDateType = .never

    /// A flag indicating if this item should be deactivated.
    var isDeactivateThisSendOn = false

    /// A flag indicating if the user's email should be hidden from the display of this item.
    var isHideMyEmailOn = false

    /// A flag indicating if this item's text should be hidden by default.
    var isHideTextByDefaultOn = false

    /// A flag indicating if the password is visible.
    var isPasswordVisible = false

    /// A flag indicating if the share sheet should be presented once this item is saved.
    var isShareOnSaveOn = false

    /// A flag indicating if the options section is expanded.
    var isOptionsExpanded = false

    /// The maximum number of times this share can be accessed before being deactivated.
    var maximumAccessCount: Int = 0

    /// The name of this item.
    var name: String = ""

    /// The private notes for this item.
    var notes: String = ""

    /// A password that can be used to limit access to this item.
    var password: String = ""

    /// The contents of this item.
    var text: String = ""

    /// The type of this item.
    var type: SendType = .text
}
