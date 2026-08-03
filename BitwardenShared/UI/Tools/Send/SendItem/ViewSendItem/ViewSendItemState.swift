import BitwardenKit
import BitwardenResources
import BitwardenSdk
import Foundation

// MARK: - ViewSendItemState

/// An object that defines the current state of a `ViewSendItemView`.
///
struct ViewSendItemState: Equatable {
    // MARK: Properties

    /// Whether the additional options section is expanded.
    var isAdditionalOptionsExpanded = false

    /// The Send restrictions enforced by policy for the active user.
    var sendPolicyOptions = SendPolicyOptions()

    /// The send to show the details of.
    var sendView: SendView

    /// A URL for sharing the send.
    var shareURL: URL?

    /// A toast message to show in the view.
    var toast: Toast?

    // MARK: Computed Properties

    /// Whether the "Make a copy" action should be offered for this disabled Send.
    ///
    /// Only offered for a disabled Text Send whose type isn't itself restricted by policy; a
    /// Send-type violation has no compliant equivalent to copy to, and File Sends can't have their
    /// attachment carried into a new Send.
    var canMakeCopy: Bool {
        isDisabled && sendView.type == .text && !isSendTypeRestricted
    }

    /// The send's share URL without a scheme for displaying in the UI.
    var displayShareURL: String? {
        shareURL?.withoutScheme
    }

    /// Whether this Send has been disabled.
    var isDisabled: Bool {
        sendView.disabled
    }

    /// Whether this Send's type is restricted by the active Send Controls policy.
    var isSendTypeRestricted: Bool {
        sendPolicyOptions.isSendTypeRestricted(for: sendView)
    }

    /// The navigation title of the view.
    var navigationTitle: String {
        switch sendView.type {
        case .file: Localizations.viewFileSend
        case .text: Localizations.viewTextSend
        }
    }

    /// The message to show in the organization policy restriction banner, or `nil` if the Send isn't
    /// disabled.
    var restrictionBannerMessage: String? {
        guard isDisabled else { return nil }
        if sendView.type == .text, isSendTypeRestricted {
            return Localizations.textSendsAreNotAllowedDescriptionLong
        }
        if sendView.type == .text {
            return Localizations.toEditThisSendMakeACopyDescriptionLong
        }
        return Localizations.thisSendIsNotCompliantDescriptionLong
    }
}
