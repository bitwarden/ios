import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - AddEditSendItemProcessorTests

class AddEditSendItemProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var configService: MockConfigService!
    var coordinator: MockCoordinator<SendItemRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var policyService: MockPolicyService!
    var sendRepository: MockSendRepository!
    var reviewPromptService: MockReviewPromptService!
    var subject: AddEditSendItemProcessor!

    /// A deletion date to use within the tests.
    let deletionDate = Date(year: 2023, month: 11, day: 5)

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        configService = MockConfigService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        policyService = MockPolicyService()
        reviewPromptService = MockReviewPromptService()
        sendRepository = MockSendRepository()
        subject = AddEditSendItemProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                configService: configService,
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                policyService: policyService,
                reviewPromptService: reviewPromptService,
                sendRepository: sendRepository,
            ),
            state: AddEditSendItemState(),
        )
    }

    override func tearDown() {
        super.tearDown()
        configService = nil
        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        policyService = nil
        sendRepository = nil
        reviewPromptService = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `sendListItemRow(copyLinkPressed())` uses the send repository to generate
    /// a url and copies it to the clipboard.
    @MainActor
    func test_perform_copyLinkPressed() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        subject.state.originalSendView = sendView
        sendRepository.shareURLResult = .success(.example)
        await subject.perform(.copyLinkPressed)

        XCTAssertEqual(sendRepository.shareURLSendView, sendView)
        XCTAssertEqual(pasteboardService.copiedString, "https://example.com")
        XCTAssertEqual(
            subject.state.toast,
            Toast(title: Localizations.valueHasBeenCopied(Localizations.sendLink)),
        )
    }

    /// `perform(_:)` with `.copyPasswordPressed` copies the password to the clipboard.
    @MainActor
    func test_perform_copyPasswordPressed() async {
        subject.state.password = "testPassword123"
        await subject.perform(.copyPasswordPressed)

        XCTAssertEqual(pasteboardService.copiedString, "testPassword123")
        XCTAssertEqual(
            subject.state.toast,
            Toast(title: Localizations.valueHasBeenCopied(Localizations.password)),
        )
    }

    /// `perform(_:)` with `sendListItemRow(deletePressed())` uses the send repository to delete the
    /// send.
    @MainActor
    func test_perform_deletePressed() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        subject.state.originalSendView = sendView
        sendRepository.deleteSendResult = .success(())
        await subject.perform(.deletePressed)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.delete)

        XCTAssertEqual(sendRepository.deleteSendSendView, sendView)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.deleting)
        XCTAssertEqual(coordinator.routes.last, .deleted)
    }

    /// `perform(_:)` with `sendListItemRow(removePassword())` uses the send repository to remove
    /// the password from a send.
    @MainActor
    func test_perform_deletePressed_networkError() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        subject.state.originalSendView = sendView
        let error = URLError(.timedOut)
        sendRepository.deleteSendResult = .failure(error)
        await subject.perform(.deletePressed)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.delete)

        XCTAssertEqual(sendRepository.deleteSendSendView, sendView)

        sendRepository.deleteSendResult = .success(())
        let errorAlertWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(errorAlertWithRetry.error as? URLError, error)
        await errorAlertWithRetry.retry()

        XCTAssertEqual(
            coordinator.loadingOverlaysShown.last?.title,
            Localizations.deleting,
        )
        XCTAssertEqual(coordinator.routes.last, .deleted)
    }

    /// `perform(_:)` with `loadData` loads the policy data for the view.
    @MainActor
    func test_perform_loadData_policies() async {
        await subject.perform(.loadData)
        XCTAssertFalse(subject.state.isSendDisabled)
        XCTAssertFalse(subject.state.isSendHideEmailDisabled)

        policyService.policyAppliesToUserResult[.disableSend] = true
        await subject.perform(.loadData)
        XCTAssertTrue(subject.state.isSendDisabled)
        XCTAssertFalse(subject.state.isSendHideEmailDisabled)

        policyService.policyAppliesToUserResult[.disableSend] = false
        policyService.isSendHideEmailDisabledByPolicy = true
        await subject.perform(.loadData)
        XCTAssertFalse(subject.state.isSendDisabled)
        XCTAssertTrue(subject.state.isSendHideEmailDisabled)
    }

    /// `perform(_:)` with `loadData` loads the correct maximum access count in the TextField.
    @MainActor
    func test_perform_loadData_maximumAccessCountUpdates() async {
        subject.state.maximumAccessCount = 42
        await subject.perform(.loadData)
        subject.state.maximumAccessCountText = "42"

        subject.state.maximumAccessCount = 0
        await subject.perform(.loadData)
        subject.state.maximumAccessCountText = ""
    }

    /// `perform(_:)` with `sendListItemRow(removePassword())` uses the send repository to remove
    /// the password from a send.
    @MainActor
    func test_perform_removePassword_success() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        subject.state.originalSendView = sendView
        sendRepository.removePasswordFromSendResult = .success(sendView)
        await subject.perform(.removePassword)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.remove)

        XCTAssertEqual(sendRepository.removePasswordFromSendSendView, sendView)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown.last?.title,
            Localizations.removingSendPassword,
        )
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.sendPasswordRemoved))
    }

    /// `perform(_:)` with `sendListItemRow(removePassword())` uses the send repository to remove
    /// the password from a send.
    @MainActor
    func test_perform_sendListItemRow_removePassword_networkError() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        subject.state.originalSendView = sendView
        let error = URLError(.timedOut)
        sendRepository.removePasswordFromSendResult = .failure(error)
        await subject.perform(.removePassword)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.remove)

        XCTAssertEqual(sendRepository.removePasswordFromSendSendView, sendView)

        sendRepository.removePasswordFromSendResult = .success(sendView)
        let errorAlertWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(errorAlertWithRetry.error as? URLError, error)
        await errorAlertWithRetry.retry()

        XCTAssertEqual(
            coordinator.loadingOverlaysShown.last?.title,
            Localizations.removingSendPassword,
        )
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.sendPasswordRemoved))
    }

    /// `perform(_:)` with `shareLinkPressed` uses the send repository to generate a url and
    /// navigates to the `.share` route.
    @MainActor
    func test_perform_shareLinkPressed() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        subject.state.originalSendView = sendView
        sendRepository.shareURLResult = .success(.example)
        await subject.perform(.shareLinkPressed)

        XCTAssertEqual(sendRepository.shareURLSendView, sendView)
        XCTAssertEqual(coordinator.routes.last, .share(url: .example))
    }

    /// `fileSelectionCompleted()` updates the state with the new file values.
    @MainActor
    func test_fileSelectionCompleted() {
        let data = Data("data".utf8)
        subject.fileSelectionCompleted(fileName: "exampleFile.txt", data: data)
        XCTAssertEqual(subject.state.fileName, "exampleFile.txt")
        XCTAssertEqual(subject.state.fileData, data)
    }

    /// `perform(_:)` with `.savePressed` and valid input saves the item.
    @MainActor
    func test_perform_savePressed_add_validated_success() async {
        subject.state.name = "Name"
        subject.state.type = .text
        subject.state.text = "Text"
        subject.state.deletionDate = .custom(deletionDate)
        subject.state.customDeletionDate = deletionDate
        let sendView = SendView.fixture(id: "SEND_ID", name: "Name")
        sendRepository.addTextSendResult = .success(sendView)

        await subject.perform(.savePressed)

        XCTAssertEqual(coordinator.loadingOverlaysShown, [
            LoadingOverlayState(title: Localizations.saving),
        ])
        XCTAssertEqual(sendRepository.addTextSendSendView?.name, "Name")
        XCTAssertEqual(sendRepository.addTextSendSendView?.text?.text, "Text")
        XCTAssertEqual(sendRepository.addTextSendSendView?.deletionDate, deletionDate)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.routes.last, .complete(sendView))
        XCTAssertEqual(reviewPromptService.userActions, [.createdNewSend])
        XCTAssertEqual(coordinator.toastsShown, [Toast(title: Localizations.newSendCreated)])
    }

    /// `perform(_:)` with `.savePressed` and valid input and http failure shows an error alert.
    @MainActor
    func test_perform_savePressed_add_validated_error() async throws {
        subject.state.name = "Name"
        subject.state.type = .text
        subject.state.text = "Text"
        subject.state.deletionDate = .custom(deletionDate)
        subject.state.customDeletionDate = deletionDate
        let error = URLError(.timedOut)
        sendRepository.addTextSendResult = .failure(error)

        await subject.perform(.savePressed)

        XCTAssertEqual(coordinator.loadingOverlaysShown, [
            LoadingOverlayState(title: Localizations.saving),
        ])
        XCTAssertEqual(sendRepository.addTextSendSendView?.name, "Name")
        XCTAssertEqual(sendRepository.addTextSendSendView?.text?.text, "Text")
        XCTAssertEqual(sendRepository.addTextSendSendView?.deletionDate, deletionDate)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)

        let sendView = SendView.fixture(id: "SEND_ID", name: "Name")
        sendRepository.addTextSendResult = .success(sendView)

        let errorAlertWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(errorAlertWithRetry.error as? URLError, error)
        await errorAlertWithRetry.retry()

        XCTAssertEqual(coordinator.routes.last, .complete(sendView))
    }

    /// `perform(_:)` with `.savePressed` and no name shows a validation alert.
    @MainActor
    func test_perform_savePressed_add_noName() async {
        subject.state.name = ""
        await subject.perform(.savePressed)

        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
        XCTAssertNil(sendRepository.addTextSendSendView)
        XCTAssertEqual(coordinator.alertShown, [
            .validationFieldRequired(fieldName: Localizations.name),
        ])
    }

    /// `perform(_:)` with `.savePressed` and no premium shows a validation alert.
    @MainActor
    func test_perform_savePressed_add_file_noPremium() async {
        sendRepository.doesActivateAccountHavePremiumResult = false
        subject.state.name = "Name"
        subject.state.fileData = Data("example".utf8)
        subject.state.fileName = "filename"
        subject.state.type = .file
        await subject.perform(.savePressed)

        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
        XCTAssertNil(sendRepository.addTextSendSendView)
        XCTAssertEqual(coordinator.alertShown, [
            Alert.defaultAlert(message: Localizations.sendFilePremiumRequired),
        ])
    }

    /// `perform(_:)` with `.savePressed` and an unverified email shows a validation alert.
    @MainActor
    func test_perform_savePressed_add_file_noVerifiedEmail() async {
        sendRepository.doesActivateAccountHavePremiumResult = true
        sendRepository.doesActiveAccountHaveVerifiedEmailResult = .success(false)
        subject.state.name = "Name"
        subject.state.fileData = Data("example".utf8)
        subject.state.fileName = "filename"
        subject.state.type = .file
        await subject.perform(.savePressed)

        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
        XCTAssertNil(sendRepository.addTextSendSendView)
        XCTAssertEqual(coordinator.alertShown, [
            Alert.defaultAlert(message: Localizations.sendFileEmailVerificationRequired),
        ])
    }

    /// `perform(_:)` with `.savePressed` and no file data shows a validation alert.
    @MainActor
    func test_perform_savePressed_add_file_noFileData() async {
        sendRepository.doesActivateAccountHavePremiumResult = true
        sendRepository.doesActiveAccountHaveVerifiedEmailResult = .success(true)
        subject.state.name = "Name"
        subject.state.fileData = nil
        subject.state.fileName = "filename"
        subject.state.type = .file
        subject.state.mode = .add
        await subject.perform(.savePressed)

        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
        XCTAssertNil(sendRepository.addTextSendSendView)
        XCTAssertEqual(coordinator.alertShown, [
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.youMustAttachAFileToSaveThisSend,
            ),
        ])
    }

    /// `perform(_:)` with `.savePressed` and no file name shows a validation alert.
    @MainActor
    func test_perform_savePressed_add_file_noFileName() async {
        sendRepository.doesActivateAccountHavePremiumResult = true
        sendRepository.doesActiveAccountHaveVerifiedEmailResult = .success(true)
        subject.state.name = "Name"
        subject.state.fileData = Data("example".utf8)
        subject.state.fileName = nil
        subject.state.type = .file
        subject.state.mode = .add
        await subject.perform(.savePressed)

        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
        XCTAssertNil(sendRepository.addTextSendSendView)
        XCTAssertEqual(coordinator.alertShown, [
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.youMustAttachAFileToSaveThisSend,
            ),
        ])
    }

    /// `perform(_:)` with `.savePressed` and file data that is too large shows a validation alert.
    @MainActor
    func test_perform_savePressed_add_file_fileDataTooLarge() async {
        sendRepository.doesActivateAccountHavePremiumResult = true
        sendRepository.doesActiveAccountHaveVerifiedEmailResult = .success(true)
        subject.state.name = "Name"
        subject.state.fileData = Data(String(repeating: "a", count: Constants.maxFileSizeBytes + 1).utf8)
        subject.state.fileName = "filename"
        subject.state.type = .file
        subject.state.mode = .add
        await subject.perform(.savePressed)

        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
        XCTAssertNil(sendRepository.addTextSendSendView)
        XCTAssertEqual(coordinator.alertShown, [
            .defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.maxFileSize,
            ),
        ])
    }

    /// `perform(_:)` with `.savePressed` and valid input in the share extension saves the item and
    /// copies the share link to the clipboard.
    @MainActor
    func test_perform_savePressed_shareExtension_validated_success() async {
        subject.state.mode = .shareExtension(.empty())
        subject.state.name = "Name"
        subject.state.type = .text
        subject.state.text = "Text"
        subject.state.deletionDate = .custom(deletionDate)
        subject.state.customDeletionDate = deletionDate
        let sendView = SendView.fixture(
            id: "SEND_ID",
            name: "Name",
            text: .fixture(text: "Text"),
        )
        sendRepository.addTextSendResult = .success(sendView)
        sendRepository.shareURLResult = .success(.example)

        await subject.perform(.savePressed)

        XCTAssertEqual(coordinator.loadingOverlaysShown, [
            LoadingOverlayState(title: Localizations.saving),
        ])
        XCTAssertEqual(sendRepository.addTextSendSendView?.name, "Name")
        XCTAssertEqual(sendRepository.addTextSendSendView?.text?.text, "Text")
        XCTAssertEqual(sendRepository.addTextSendSendView?.deletionDate, deletionDate)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(sendRepository.shareURLSendView, sendView)
        XCTAssertEqual(pasteboardService.copiedString, "https://example.com")
        XCTAssertEqual(
            subject.state.toast,
            Toast(title: Localizations.valueHasBeenCopied(Localizations.sendLink)),
        )

        subject.receive(.toastShown(nil))

        XCTAssertEqual(coordinator.routes.last, .complete(sendView))
    }

    /// `perform(_:)` with `.savePressed` while editing and valid input updates the item.
    @MainActor
    func test_perform_savePressed_edit_validated_success() async {
        subject.state.mode = .edit
        subject.state.name = "Name"
        subject.state.type = .text
        subject.state.text = "Text"
        subject.state.deletionDate = .custom(deletionDate)
        subject.state.customDeletionDate = deletionDate
        let sendView = SendView.fixture(id: "SEND_ID", name: "Name")
        sendRepository.updateSendResult = .success(sendView)

        await subject.perform(.savePressed)

        XCTAssertEqual(coordinator.loadingOverlaysShown, [
            LoadingOverlayState(title: Localizations.saving),
        ])
        XCTAssertEqual(sendRepository.updateSendSendView?.name, "Name")
        XCTAssertEqual(sendRepository.updateSendSendView?.text?.text, "Text")
        XCTAssertEqual(sendRepository.updateSendSendView?.deletionDate, deletionDate)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.routes.last, .complete(sendView))
        XCTAssertEqual(coordinator.toastsShown, [Toast(title: Localizations.sendUpdated)])
    }

    /// `perform(_:)` with `.savePressed` while editing and valid input and http failure shows an
    /// alert.
    @MainActor
    func test_perform_savePressed_edit_validated_error() async throws {
        subject.state.mode = .edit
        subject.state.name = "Name"
        subject.state.type = .text
        subject.state.text = "Text"
        subject.state.deletionDate = .custom(deletionDate)
        subject.state.customDeletionDate = deletionDate
        let error = URLError(.timedOut)
        sendRepository.updateSendResult = .failure(error)

        await subject.perform(.savePressed)

        XCTAssertEqual(coordinator.loadingOverlaysShown, [
            LoadingOverlayState(title: Localizations.saving),
        ])
        XCTAssertEqual(sendRepository.updateSendSendView?.name, "Name")
        XCTAssertEqual(sendRepository.updateSendSendView?.text?.text, "Text")
        XCTAssertEqual(sendRepository.updateSendSendView?.deletionDate, deletionDate)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)

        let sendView = SendView.fixture(id: "SEND_ID", name: "Name")
        sendRepository.updateSendResult = .success(sendView)

        let errorAlertWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(errorAlertWithRetry.error as? URLError, error)
        await errorAlertWithRetry.retry()

        XCTAssertEqual(coordinator.routes.last, .complete(sendView))
    }

    /// `perform(_:)` with `.savePressed` while editing and invalid input shows a validation alert.
    @MainActor
    func test_perform_savePressed_edit_unvalidated() async {
        subject.state.mode = .edit
        subject.state.name = ""
        await subject.perform(.savePressed)

        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
        XCTAssertNil(sendRepository.updateSendSendView)
        XCTAssertEqual(coordinator.alertShown, [
            .validationFieldRequired(fieldName: Localizations.name),
        ])
    }

    /// `receive(_:)` with `.chooseFilePressed` navigates to the document browser.
    @MainActor
    func test_receive_chooseFilePressed() async throws {
        subject.receive(.chooseFilePressed)

        let alert = try XCTUnwrap(coordinator.alertShown.last)

        try await alert.tapAction(title: Localizations.browse)
        XCTAssertEqual(coordinator.routes.last, .fileSelection(.file))
        XCTAssertIdentical(coordinator.contexts.last as? FileSelectionDelegate, subject)

        try await alert.tapAction(title: Localizations.camera)
        XCTAssertEqual(coordinator.routes.last, .fileSelection(.camera))
        XCTAssertIdentical(coordinator.contexts.last as? FileSelectionDelegate, subject)

        try await alert.tapAction(title: Localizations.photos)
        XCTAssertEqual(coordinator.routes.last, .fileSelection(.photo))
        XCTAssertIdentical(coordinator.contexts.last as? FileSelectionDelegate, subject)
    }

    /// `receive(_:)` with `.deletionDateChanged` updates the deletion date.
    @MainActor
    func test_receive_deletionDateChanged() {
        subject.state.deletionDate = .sevenDays
        subject.receive(.deletionDateChanged(.thirtyDays))

        XCTAssertEqual(subject.state.deletionDate, .thirtyDays)
    }

    /// `receive(_:)` with `.dismissPressed` navigates to the dismiss route.
    @MainActor
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)

        XCTAssertEqual(coordinator.routes.last, .cancel)
    }

    /// `receive(_:)` with `.generatePasswordPressed` navigates to the generator when password is empty.
    @MainActor
    func test_receive_generatePasswordPressed_emptyPassword() {
        subject.state.password = ""
        subject.receive(.generatePasswordPressed)

        XCTAssertEqual(coordinator.routes.last, .generator)
    }

    /// `receive(_:)` with `.generatePasswordPressed` shows a confirmation alert when password exists.
    @MainActor
    func test_receive_generatePasswordPressed_existingPassword() async throws {
        subject.state.password = "existingPassword"
        subject.receive(.generatePasswordPressed)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.passwordOverrideAlert)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.no)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.yes)

        try await alert.tapAction(title: Localizations.yes)
        XCTAssertEqual(coordinator.routes.last, .generator)
    }

    /// `didCancelGenerator()` dismisses the generator.
    @MainActor
    func test_didCancelGenerator() {
        subject.didCancelGenerator()

        XCTAssertEqual(coordinator.routes.last, .dismiss(nil))
    }

    /// `didCompleteGenerator(for:with:)` updates the password and dismisses the generator.
    @MainActor
    func test_didCompleteGenerator() {
        subject.state.password = ""
        subject.didCompleteGenerator(for: .password, with: "generatedPassword123")

        XCTAssertEqual(subject.state.password, "generatedPassword123")
        XCTAssertEqual(coordinator.routes.last, .dismiss(nil))
    }

    /// `didCompleteGenerator(for:with:)` does not update password for non-password types.
    @MainActor
    func test_didCompleteGenerator_username() {
        subject.state.password = "originalPassword"
        subject.didCompleteGenerator(for: .username, with: "generatedUsername")

        XCTAssertEqual(subject.state.password, "originalPassword")
        XCTAssertEqual(coordinator.routes.last, .dismiss(nil))
    }

    /// `receive(_:)` with `.hideMyEmailChanged` updates the hide my email toggle.
    @MainActor
    func test_receive_hideMyEmailChanged() {
        subject.state.isHideMyEmailOn = false
        subject.receive(.hideMyEmailChanged(true))

        XCTAssertTrue(subject.state.isHideMyEmailOn)
    }

    /// `receive(_:)` with `.hideTextByDefaultChanged` updates the hide text by default toggle.
    @MainActor
    func test_receive_hideTextByDefaultChanged() {
        subject.state.isHideTextByDefaultOn = false
        subject.receive(.hideTextByDefaultChanged(true))

        XCTAssertTrue(subject.state.isHideTextByDefaultOn)
    }

    /// `receive(_:)` with `.maximumAccessCountChanged` updates the maximum access count.
    @MainActor
    func test_receive_maximumAccessCountChanged() {
        subject.state.maximumAccessCount = 0
        subject.receive(.maximumAccessCountStepperChanged(42))

        XCTAssertEqual(subject.state.maximumAccessCount, 42)
        XCTAssertEqual(subject.state.maximumAccessCountText, "42")
    }

    /// `receive(_:)` with `.nameChanged` updates the name.
    @MainActor
    func test_receive_nameChanged() {
        subject.state.name = ""
        subject.receive(.nameChanged("Name"))

        XCTAssertEqual(subject.state.name, "Name")
    }

    /// `receive(_:)` with `.notesChanged` updates the notes.
    @MainActor
    func test_receive_notesChanged() {
        subject.state.notes = ""
        subject.receive(.notesChanged("Notes"))

        XCTAssertEqual(subject.state.notes, "Notes")
    }

    /// `receive(_:)` with `.optionsPressed` expands and collapses the options.
    @MainActor
    func test_receive_optionsPressed() {
        subject.state.isOptionsExpanded = false
        subject.receive(.optionsPressed)
        XCTAssertTrue(subject.state.isOptionsExpanded)

        subject.receive(.optionsPressed)
        XCTAssertFalse(subject.state.isOptionsExpanded)
    }

    /// `receive(_:)` with `.passwordChanged` updates the password.
    @MainActor
    func test_receive_passwordChanged() {
        subject.state.password = ""
        subject.receive(.passwordChanged("password"))

        XCTAssertEqual(subject.state.password, "password")
    }

    /// `receive(_:)` with `.passwordVisibleChanged` updates the password visibility.
    @MainActor
    func test_receive_passwordVisibleChanged() {
        subject.state.isPasswordVisible = false
        subject.receive(.passwordVisibleChanged(true))

        XCTAssertTrue(subject.state.isPasswordVisible)
    }

    /// `receive(_:)` with `.textChanged` updates the text.
    @MainActor
    func test_receive_textChanged() {
        subject.state.text = ""
        subject.receive(.textChanged("Text"))

        XCTAssertEqual(subject.state.text, "Text")
    }

    /// `receive(_:)` with `.toastShown` updates the toast value in the state.
    @MainActor
    func test_receive_toastShown() {
        subject.state.toast = Toast(title: "toasty")
        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    // MARK: Access Type Tests

    /// `receive(_:)` with `.accessTypeChanged` updates the access type.
    @MainActor
    func test_receive_accessTypeChanged() {
        subject.state.accessType = .anyoneWithLink
        subject.receive(.accessTypeChanged(.anyoneWithPassword))
        XCTAssertEqual(subject.state.accessType, .anyoneWithPassword)
    }

    /// `receive(_:)` with `.accessTypeChanged` to specific people adds an empty email row for premium users.
    @MainActor
    func test_receive_accessTypeChanged_specificPeople_addsEmptyEmail() {
        subject.state.hasPremium = true
        subject.state.accessType = .anyoneWithLink
        subject.state.recipientEmails = []
        subject.receive(.accessTypeChanged(.specificPeople))
        XCTAssertEqual(subject.state.accessType, .specificPeople)
        XCTAssertEqual(subject.state.recipientEmails, [""])
    }

    /// `receive(_:)` with `.accessTypeChanged` to specific people doesn't add email if already exists.
    @MainActor
    func test_receive_accessTypeChanged_specificPeople_existingEmails() {
        subject.state.hasPremium = true
        subject.state.accessType = .anyoneWithLink
        subject.state.recipientEmails = ["test@example.com"]
        subject.receive(.accessTypeChanged(.specificPeople))
        XCTAssertEqual(subject.state.accessType, .specificPeople)
        XCTAssertEqual(subject.state.recipientEmails, ["test@example.com"])
    }

    /// `receive(_:)` with `.accessTypeChanged` to specific people shows premium alert for non-premium users.
    @MainActor
    func test_receive_accessTypeChanged_specificPeople_nonPremium_showsAlert() async throws {
        subject.state.hasPremium = false
        subject.state.accessType = .anyoneWithLink
        subject.receive(.accessTypeChanged(.specificPeople))

        // Access type should remain unchanged
        XCTAssertEqual(subject.state.accessType, .anyoneWithLink)

        // Alert should be shown
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.premiumSubscriptionRequired)
        XCTAssertEqual(alert.message, Localizations.sharingWithSpecificPeopleIsPremiumFeatureDescriptionLong)
    }

    /// `receive(_:)` with `.accessTypeChanged` to specific people opens upgrade URL when user taps
    /// "Upgrade to Premium" in the alert.
    @MainActor
    func test_receive_accessTypeChanged_specificPeople_nonPremium_upgradeAction() async throws {
        subject.state.hasPremium = false
        subject.state.accessType = .anyoneWithLink
        subject.receive(.accessTypeChanged(.specificPeople))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.upgradeToPremium)

        XCTAssertNotNil(subject.state.url)
    }

    /// `receive(_:)` with `.addRecipientEmail` adds an empty email to the list.
    @MainActor
    func test_receive_addRecipientEmail() {
        subject.state.recipientEmails = ["test@example.com"]
        subject.receive(.addRecipientEmail)
        XCTAssertEqual(subject.state.recipientEmails, ["test@example.com", ""])
    }

    /// `receive(_:)` with `.clearURL` clears the URL in the state.
    @MainActor
    func test_receive_clearURL() {
        subject.state.url = URL(string: "https://example.com")!
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// `receive(_:)` with `.recipientEmailChanged` updates the email at the specified index.
    @MainActor
    func test_receive_recipientEmailChanged() {
        subject.state.recipientEmails = ["", ""]
        subject.receive(.recipientEmailChanged(index: 0, value: "test@example.com"))
        XCTAssertEqual(subject.state.recipientEmails, ["test@example.com", ""])
    }

    /// `receive(_:)` with `.recipientEmailChanged` does nothing for invalid index.
    @MainActor
    func test_receive_recipientEmailChanged_invalidIndex() {
        subject.state.recipientEmails = ["test@example.com"]
        subject.receive(.recipientEmailChanged(index: 5, value: "new@example.com"))
        XCTAssertEqual(subject.state.recipientEmails, ["test@example.com"])
    }

    /// `receive(_:)` with `.removeRecipientEmail` removes the email at the specified index.
    @MainActor
    func test_receive_removeRecipientEmail() {
        subject.state.recipientEmails = ["first@example.com", "second@example.com"]
        subject.receive(.removeRecipientEmail(index: 0))
        XCTAssertEqual(subject.state.recipientEmails, ["second@example.com"])
    }

    /// `receive(_:)` with `.removeRecipientEmail` does nothing for invalid index.
    @MainActor
    func test_receive_removeRecipientEmail_invalidIndex() {
        subject.state.recipientEmails = ["test@example.com"]
        subject.receive(.removeRecipientEmail(index: 5))
        XCTAssertEqual(subject.state.recipientEmails, ["test@example.com"])
    }

    // MARK: Validation Tests

    /// `perform(_:)` with `.savePressed` and specific people with invalid email shows validation alert.
    @MainActor
    func test_perform_savePressed_specificPeople_invalidEmail() async {
        subject.state.name = "Name"
        subject.state.accessType = .specificPeople
        subject.state.recipientEmails = ["invalidemail"]
        await subject.perform(.savePressed)

        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
        XCTAssertEqual(coordinator.alertShown, [
            .invalidEmail,
        ])
    }

    /// `perform(_:)` with `.savePressed` and specific people with no emails shows validation alert.
    @MainActor
    func test_perform_savePressed_specificPeople_noEmails() async {
        subject.state.name = "Name"
        subject.state.accessType = .specificPeople
        subject.state.recipientEmails = []
        await subject.perform(.savePressed)

        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
        XCTAssertEqual(coordinator.alertShown, [
            .validationFieldRequired(fieldName: Localizations.email),
        ])
    }

    /// `perform(_:)` with `.savePressed` and specific people with emails containing whitespace
    /// and mixed case normalizes them before validation and saving.
    @MainActor
    func test_perform_savePressed_specificPeople_normalizesEmails() async {
        subject.state.name = "Name"
        subject.state.type = .text
        subject.state.accessType = .specificPeople
        subject.state.recipientEmails = ["  TEST@Example.COM  ", "  Another@TEST.com\n", ""]
        subject.state.deletionDate = .custom(deletionDate)
        subject.state.customDeletionDate = deletionDate
        let sendView = SendView.fixture(id: "SEND_ID", name: "Name")
        sendRepository.addTextSendResult = .success(sendView)

        await subject.perform(.savePressed)

        XCTAssertEqual(coordinator.loadingOverlaysShown, [
            LoadingOverlayState(title: Localizations.saving),
        ])
        XCTAssertEqual(sendRepository.addTextSendSendView?.emails, ["test@example.com", "another@test.com"])
        XCTAssertEqual(sendRepository.addTextSendSendView?.authType, .email)
    }

    /// `perform(_:)` with `.savePressed` and specific people with only empty emails shows validation alert.
    @MainActor
    func test_perform_savePressed_specificPeople_onlyEmptyEmails() async {
        subject.state.name = "Name"
        subject.state.accessType = .specificPeople
        subject.state.recipientEmails = ["", ""]
        await subject.perform(.savePressed)

        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
        XCTAssertEqual(coordinator.alertShown, [
            .validationFieldRequired(fieldName: Localizations.email),
        ])
    }

    /// `perform(_:)` with `.savePressed` and specific people with only whitespace emails shows validation alert.
    @MainActor
    func test_perform_savePressed_specificPeople_onlyWhitespaceEmails() async {
        subject.state.name = "Name"
        subject.state.accessType = .specificPeople
        subject.state.recipientEmails = ["   ", "\t\n", "  "]
        await subject.perform(.savePressed)

        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
        XCTAssertEqual(coordinator.alertShown, [
            .validationFieldRequired(fieldName: Localizations.email),
        ])
    }

    /// `perform(_:)` with `.savePressed` and specific people with valid emails saves successfully.
    @MainActor
    func test_perform_savePressed_specificPeople_validEmails() async {
        subject.state.name = "Name"
        subject.state.type = .text
        subject.state.accessType = .specificPeople
        subject.state.recipientEmails = ["test@example.com", "another@example.com"]
        subject.state.deletionDate = .custom(deletionDate)
        subject.state.customDeletionDate = deletionDate
        let sendView = SendView.fixture(id: "SEND_ID", name: "Name")
        sendRepository.addTextSendResult = .success(sendView)

        await subject.perform(.savePressed)

        XCTAssertEqual(coordinator.loadingOverlaysShown, [
            LoadingOverlayState(title: Localizations.saving),
        ])
        XCTAssertEqual(sendRepository.addTextSendSendView?.emails, ["test@example.com", "another@example.com"])
        XCTAssertEqual(sendRepository.addTextSendSendView?.authType, .email)
    }

    // MARK: LoadData Tests

    /// `perform(_:)` with `loadData` loads the premium status and feature flag.
    @MainActor
    func test_perform_loadData_premiumAndFeatureFlag() async {
        sendRepository.doesActivateAccountHavePremiumResult = true
        configService.featureFlagsBool[.sendEmailVerification] = true

        await subject.perform(.loadData)

        XCTAssertTrue(subject.state.hasPremium)
        XCTAssertTrue(subject.state.isSendEmailVerificationEnabled)
    }

    /// `perform(_:)` with `loadData` loads false for premium and feature flag when not available.
    @MainActor
    func test_perform_loadData_noPremiumNoFeatureFlag() async {
        sendRepository.doesActivateAccountHavePremiumResult = false
        configService.featureFlagsBool[.sendEmailVerification] = false

        await subject.perform(.loadData)

        XCTAssertFalse(subject.state.hasPremium)
        XCTAssertFalse(subject.state.isSendEmailVerificationEnabled)
    }

    // MARK: ProfileSwitcherHandler

    /// `dismissProfileSwitcher` calls the coordinator to dismiss the profile switcher.
    @MainActor
    func test_dismissProfileSwitcher() {
        subject.dismissProfileSwitcher()

        XCTAssertEqual(coordinator.routes, [.dismiss(nil)])
    }

    /// `showProfileSwitcher` calls the coordinator to show the profile switcher.
    @MainActor
    func test_showProfileSwitcher() {
        subject.showProfileSwitcher()

        XCTAssertEqual(coordinator.routes, [.viewProfileSwitcher])
    }
} // swiftlint:disable:this file_length
