import BitwardenKit
import BitwardenResources
@preconcurrency import BitwardenSdk
import Foundation

// MARK: - AddEditSendItemState

/// An object that defines the current state of a `AddEditSendItemView`.
///
struct AddEditSendItemState: Equatable, Sendable {
    // MARK: Types

    enum Mode: Equatable {
        /// A mode for adding a new send.
        case add

        /// A mode for editing a preexisting send.
        case edit

        /// A mode for adding a new send using the share extension.
        case shareExtension(ProfileSwitcherState)
    }

    // MARK: Properties

    /// The access id for this send.
    var accessId: String?

    /// The access type for this send (who can view it).
    var accessType: SendAccessType = .anyoneWithLink

    /// The number of times this send has been accessed.
    var currentAccessCount: Int?

    /// The custom deletion date.
    var customDeletionDate = Date.midnightOneWeekFromToday() ?? Date()

    /// The deletion date for this item.
    var deletionDate: SendDeletionDateType = .sevenDays

    /// The expiration date for this item.
    var expirationDate: Date?

    /// The data for the selected file.
    var fileData: Data?

    /// The name of the selected file.
    var fileName: String?

    /// A description of the size of the file attached to this send.
    var fileSize: String?

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

    /// Whether the user has a premium account.
    var hasPremium = false

    /// Whether the send email verification feature flag is enabled.
    var isSendEmailVerificationEnabled = false

    /// Whether sends are disabled via a policy.
    var isSendDisabled = false

    /// Whether the send hide email option is disabled via a policy.
    var isSendHideEmailDisabled = false

    /// The key for this send.
    var key: String?

    /// The maximum number of times this share can be accessed before being deactivated.
    var maximumAccessCount: Int = 0

    /// The text representation of the maximum access count.
    var maximumAccessCountText: String = ""

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

    /// The list of recipient emails for the "specific people" access type.
    var recipientEmails: [String] = []

    /// The contents of this item.
    var text: String = ""

    /// A toast message to show in the view.
    var toast: Toast?

    /// The type of this item.
    var type: SendType = .text

    // MARK: Computed Properties

    /// The access type options available in the menu.
    /// The "Specific People" option is shown when the feature flag is enabled (for all users).
    var availableAccessTypes: [SendAccessType] {
        if isSendEmailVerificationEnabled {
            SendAccessType.allCases
        } else {
            [.anyoneWithLink, .anyoneWithPassword]
        }
    }

    /// The recipient emails filtered to remove empty entries and normalized
    /// (trimmed whitespace and lowercased) for validation and API submission.
    var normalizedRecipientEmails: [String] {
        recipientEmails
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }

    /// The URL to open in Safari (e.g., upgrade to premium page).
    var url: URL?

    /// The deletion date options available in the menu.
    var availableDeletionDateTypes: [SendDeletionDateType] {
        switch mode {
        case .add, .shareExtension:
            [.oneHour, .oneDay, .twoDays, .threeDays, .sevenDays, .thirtyDays]
        case .edit:
            [.oneHour, .oneDay, .twoDays, .threeDays, .sevenDays, .thirtyDays, .custom(customDeletionDate)]
        }
    }

    /// The navigation title to use for the view.
    var navigationTitle: String {
        switch mode {
        case .add,
             .shareExtension:
            switch type {
            case .file:
                Localizations.newFileSend
            case .text:
                Localizations.newTextSend
            }
        case .edit:
            switch type {
            case .file:
                Localizations.editFileSend
            case .text:
                Localizations.editTextSend
            }
        }
    }
}

extension AddEditSendItemState {
    /// Creates a new `AddEditSendItemState`.
    ///
    /// - Parameter sendView: The `SendView` to use to instantiate this state.
    ///
    init(sendView: SendView) {
        // Determine access type: if the send has a password, use "Anyone with password",
        // otherwise map from the authType. This ensures backwards compatibility with
        // sends created before the access type feature was introduced.
        let accessType: SendAccessType = if sendView.hasPassword {
            .anyoneWithPassword
        } else {
            SendAccessType(authType: sendView.authType)
        }

        self.init(
            accessId: sendView.accessId,
            accessType: accessType,
            currentAccessCount: Int(sendView.accessCount),
            customDeletionDate: sendView.deletionDate,
            deletionDate: .custom(sendView.deletionDate),
            expirationDate: sendView.expirationDate,
            fileData: nil,
            fileName: sendView.file?.fileName,
            fileSize: sendView.file?.sizeName,
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
            recipientEmails: sendView.emails,
            text: sendView.text?.text ?? "",
            type: SendType(sendType: sendView.type),
        )
    }

    /// Returns a `SendView` based on the properties of the `AddEditSendItemState`.
    ///
    func newSendView() -> SendView {
        let deletionDate = deletionDate.calculateDate() ?? Date()

        // Determine if the send should have a password:
        // - If access type is not "Anyone with password", no password
        // - If a new password is entered, the send has a password
        // - If editing and no new password entered, preserve the original password state
        let hasPassword: Bool = if accessType != .anyoneWithPassword {
            false
        } else if !password.isEmpty {
            true
        } else {
            originalSendView?.hasPassword ?? false
        }

        return SendView(
            id: id,
            accessId: accessId,
            name: name,
            notes: notes.nilIfEmpty,
            key: key,
            newPassword: accessType == .anyoneWithPassword ? password.nilIfEmpty : nil,
            hasPassword: hasPassword,
            type: .init(type: type),
            file: type == .file ? newFileView() : nil,
            text: type == .text ? newTextView() : nil,
            maxAccessCount: maximumAccessCount == 0 ? nil : UInt32(maximumAccessCount),
            accessCount: 0, // Defaulting to `0`, since the API ignores the values we set here.
            disabled: isDeactivateThisSendOn,
            hideEmail: isHideMyEmailOn,
            revisionDate: Date(),
            deletionDate: deletionDate,
            // If the send has an expiration date, reset it to the deletion date to prevent a server
            // error which disallows editing a send after it has expired.
            expirationDate: expirationDate != nil ? deletionDate : nil,
            emails: accessType == .specificPeople ? normalizedRecipientEmails : [],
            authType: accessType.authType,
        )
    }

    /// Returns a `SendTextView` based on the properties of the `AddEditSendItemState`.
    ///
    private func newTextView() -> SendTextView {
        SendTextView(
            text: text,
            hidden: isHideTextByDefaultOn,
        )
    }

    /// Returns a `SendFileView` based on the properties of the `AddEditSendItemState`.
    ///
    private func newFileView() -> SendFileView {
        SendFileView(
            id: nil,
            fileName: fileName ?? "",
            size: nil,
            sizeName: nil,
        )
    }
}
