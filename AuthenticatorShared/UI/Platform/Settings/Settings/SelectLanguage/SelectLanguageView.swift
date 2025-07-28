import BitwardenResources
import SwiftUI

// MARK: - SelectLanguageView

/// A view that shows a list of all the available languages to select from..
///
struct SelectLanguageView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<SelectLanguageState, SelectLanguageAction, Void>

    // MARK: View

    var body: some View {
        VStack(spacing: 0) {
            ForEach(LanguageOption.allCases) { languageOption in
                languageOptionRow(languageOption)
            }
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        .cornerRadius(10)
        .scrollView()
        .navigationBar(title: Localizations.selectLanguage, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
    }

    // MARK: Private Views

    /// Show a checkmark as the trailing image for the currently selected language.
    @ViewBuilder
    private func checkmarkView(_ languageOption: LanguageOption) -> some View {
        if languageOption == store.state.currentLanguage {
            Image(asset: Asset.Images.check)
                .imageStyle(.rowIcon)
        }
    }

    /// Construct the row for the language option.
    private func languageOptionRow(_ languageOption: LanguageOption) -> some View {
        SettingsListItem(
            languageOption.title,
            hasDivider: !languageOption.isLast
        ) {
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
