import BitwardenSdk
import Foundation

// MARK: - AddEditSendItemState

/// An object that defines the current state of a `AddEditSendItemView`.
///
struct AddEditSendItemState: Equatable {
    // MARK: Types

    enum Mode: Equatable {
        /// A mode for adding a new send.
        case add

        /// A mode for editing a preexisting send.
        case edit

        /// A mode for adding a new send using the share extension.
        case shareExtension(ProfileSwitcherState)

        /// The navigation title to use for this mode.
        var navigationTitle: String {
            switch self {
            case .add:
                Localizations.addSend
            case .edit:
                Localizations.editSend
            case .shareExtension:
                Localizations.addSend
            }
        }
    }

    // MARK: Properties

    /// The access id for this send.
    var accessId: String?

    /// The number of times this send has been accessed.
    var currentAccessCount: Int?

    /// The custom deletion date.
    var customDeletionDate = Date.midnightOneWeekFromToday() ?? Date()

    /// The custom expiration date.
    var customExpirationDate: Date?

    /// The deletion date for this item.
    var deletionDate: SendDeletionDateType = .sevenDays

    /// The expiration date for this item.
    var expirationDate: SendExpirationDateType = .never

    /// The data for the selected file.
    var fileData: Data?

    /// The name of the selected file.
    var fileName: String?

    /// A description of the size of the file attached to this send.
    var fileSize: String?

    /// A flag indicating if the active account has access to premium features.
    var hasPremium = false

    /// The id for this send.
    var id: String?

    /// A flag indicating if this item should be deactivated.
    var isDeactivateThisSendOn = false

    /// A flag indicating if the user's email should be hidden from the display of this item.
    var isHideMyEmailOn = false

    /// A flag indicating if this item's text should be hidden by default.
    var isHideTextByDefaultOn = false

    /// A flag indicating if the options section is expanded.
    var isOptionsExpanded = false

    /// A flag indicating if the password is visible.
    var isPasswordVisible = false

    /// Whether sends are disabled via a policy.
    var isSendDisabled = false

    /// Whether the send hide email option is disabled via a policy.
    var isSendHideEmailDisabled = false

    /// The key for this send.
    var key: String?

    /// The maximum number of times this share can be accessed before being deactivated.
    var maximumAccessCount: Int = 0

    /// The text representation of the maximum access count.
    var maximumAccessCountText: String {
        maximumAccessCount == 0 ? "" : "\(maximumAccessCount)"
    }

    /// The mode for this view.
    var mode: Mode = .add

    /// The name of this item.
    var name: String = ""

    /// The private notes for this item.
    var notes: String = ""

    /// The original send view that is being edited.
    var originalSendView: SendView?

    /// A password that can be used to limit access to this item.
    var password: String = ""

    /// The contents of this item.
    var text: String = ""

    /// A toast message to show in the view.
    var toast: Toast?

    /// The type of this item.
    var type: SendType = .text
}

extension AddEditSendItemState {
    /// Creates a new `AddEditSendItemState`.
    ///
    /// - Parameters:
    ///   - sendView: The `SendView` to use to instantiate this state.
    ///   - hasPremium: A flag indicating if the active account has premium access.
    ///
    init(sendView: SendView, hasPremium: Bool) {
        self.init(
            accessId: sendView.accessId,
            currentAccessCount: Int(sendView.accessCount),
            customDeletionDate: sendView.deletionDate,
            customExpirationDate: sendView.expirationDate,
            deletionDate: .custom,
            expirationDate: .custom,
            fileData: nil,
            fileName: sendView.file?.fileName,
            fileSize: sendView.file?.sizeName,
            hasPremium: hasPremium,
            id: sendView.id,
            isDeactivateThisSendOn: sendView.disabled,
            isHideMyEmailOn: sendView.hideEmail,
            isHideTextByDefaultOn: sendView.text?.hidden ?? false,
            isOptionsExpanded: false,
            isPasswordVisible: false,
            key: sendView.key,
            maximumAccessCount: sendView.maxAccessCount.map(Int.init) ?? 0,
            mode: .edit,
            name: sendView.name,
            notes: sendView.notes ?? "",
            originalSendView: sendView,
            password: "",
            text: sendView.text?.text ?? "",
            type: SendType(sendType: sendView.type)
        )
    }

    /// Returns a `SendView` based on the properties of the `AddEditSendItemState`.
    ///
    func newSendView() -> SendView {
        SendView(
            id: id,
            accessId: accessId,
            name: name,
            notes: notes.nilIfEmpty,
            key: key,
            newPassword: password.nilIfEmpty,
            hasPassword: !password.isEmpty,
            type: .init(type: type),
            file: type == .file ? newFileView() : nil,
            text: type == .text ? newTextView() : nil,
            maxAccessCount: maximumAccessCount == 0 ? nil : UInt32(maximumAccessCount),
            accessCount: 0, // Defaulting to `0`, since the API ignores the values we set here.
            disabled: isDeactivateThisSendOn,
            hideEmail: isHideMyEmailOn,
            revisionDate: Date(),
            deletionDate: deletionDate.calculateDate(customValue: customDeletionDate) ?? Date(),
            expirationDate: expirationDate.calculateDate(customValue: customExpirationDate)
        )
    }

    /// Returns a `SendTextView` based on the properties of the `AddEditSendItemState`.
    ///
    private func newTextView() -> SendTextView {
        SendTextView(
            text: text,
            hidden: isHideTextByDefaultOn
        )
    }

    /// Returns a `SendFileView` based on the properties of the `AddEditSendItemState`.
    ///
    private func newFileView() -> SendFileView {
        SendFileView(
            id: nil,
            fileName: fileName ?? "",
            size: nil,
            sizeName: nil
        )
    }
}
