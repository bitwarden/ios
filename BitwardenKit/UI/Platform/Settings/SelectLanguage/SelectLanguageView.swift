import BitwardenResources
import SwiftUI

// MARK: - SelectLanguageView

/// A view that shows a list of all the available languages to select from.
///
public struct SelectLanguageView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<SelectLanguageState, SelectLanguageAction, Void>

    // MARK: View

    public var body: some View {
        ContentBlock(dividerLeadingPadding: 16) {
            ForEach(LanguageOption.allCases) { languageOption in
                languageOptionRow(languageOption)
            }
        }
        .scrollView()
        .navigationBar(title: Localizations.selectLanguage, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
    }

    // MARK: Initializer

    /// Initializes a `SelectLanguageView`.
    ///
    /// - Parameters:
    ///   - store: The `Store` for this view.
    ///
    public init(store: Store<SelectLanguageState, SelectLanguageAction, Void>) {
        self.store = store
    }

    // MARK: Private Views

    /// Show a checkmark as the trailing image for the currently selected language.
    @ViewBuilder
    private func checkmarkView(_ languageOption: LanguageOption) -> some View {
        if languageOption == store.state.currentLanguage {
            Image(asset: SharedAsset.Icons.check24)
                .imageStyle(.rowIcon)
        }
    }

    /// Construct the row for the language option.
    private func languageOptionRow(_ languageOption: LanguageOption) -> some View {
        SettingsListItem(languageOption.title) {
            store.send(.languageTapped(languageOption))
        } trailingContent: {
            checkmarkView(languageOption)
        }
    }
}

// MARK: - Previews

#Preview {
    SelectLanguageView(store: Store(processor: StateProcessor(state: SelectLanguageState())))
}
