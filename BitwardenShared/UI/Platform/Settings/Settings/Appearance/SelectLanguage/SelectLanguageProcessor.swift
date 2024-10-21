// MARK: - SelectLanguageDelegate

/// The delegate for updating the parent view after a language has been selected.
@MainActor
protocol SelectLanguageDelegate: AnyObject {
    /// A language has been selected.
    func languageSelected(_ languageOption: LanguageOption)
}

// MARK: - SelectLanguageProcessor

/// The processor used to manage state and handle actions for the `SelectLanguageView`.
///
final class SelectLanguageProcessor: StateProcessor<SelectLanguageState, SelectLanguageAction, Void> {
    // MARK: Types

    typealias Services = HasStateService

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The delegate for handling the selection flow.
    private weak var delegate: SelectLanguageDelegate?

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a `SelectLanguageProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - delegate: The delegate for handling the selection flow.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        delegate: SelectLanguageDelegate?,
        services: Services,
        state: SelectLanguageState
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: SelectLanguageAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .languageTapped(languageOption):
            changeLanguage(to: languageOption)
        }
    }

    // MARK: Private Methods

    /// Update the language and show the confirmation alert.
    private func changeLanguage(to languageOption: LanguageOption) {
        // Don't do anything if the user has selected the currently selected language.
        guard languageOption != state.currentLanguage else { return }

        // Save the value.
        state.currentLanguage = languageOption
        services.stateService.appLanguage = languageOption
        delegate?.languageSelected(languageOption)

        // Show the confirmation alert and close the view after the user clicks ok.
        coordinator.showAlert(.languageChanged(to: languageOption.title) { [weak self] in
            self?.coordinator.navigate(to: .dismiss)
        })
    }
}
