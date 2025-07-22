import BitwardenResources
import SwiftUI

// MARK: - MasterPasswordGuidanceView

/// A view that presents the user with guidance about how to create a strong master password.
///
struct MasterPasswordGuidanceView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<Void, MasterPasswordGuidanceAction, Void>

    // MARK: View

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .center, spacing: 12) {
                Text(Localizations.aSecureMemorablePassword)
                    .styleGuide(.title2, weight: .semibold)

                Text(Localizations.aSecureMemorablePasswordDescriptionLong)
                    .styleGuide(.body)
            }
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
            .padding(.top, 12)

            NumberedList {
                numberedRowView(
                    title: Localizations.chooseThreeOrFourRandomWords,
                    subtitle: Localizations.chooseThreeOrFourRandomWordsDescriptionLong
                )

                numberedRowView(
                    title: Localizations.combineThoseWordsTogether,
                    subtitle: Localizations.combineThoseWordsTogetherDescriptionLong
                )

                numberedRowView(
                    title: Localizations.makeItYours,
                    subtitle: Localizations.makeItYoursDescriptionLong
                )
            }

            ActionCard(
                title: Localizations.needSomeInspiration,
                actionButtonState: ActionCard.ButtonState(title: Localizations.checkOutThePassphraseGenerator) {
                    store.send(.generatePasswordPressed)
                }
            )
        }
        .scrollView()
        .navigationBar(title: Localizations.masterPasswordHelp, titleDisplayMode: .inline)
        .toolbar {
            closeToolbarItem {
                store.send(.dismiss)
            }
        }
    }

    // MARK: Private Views

    /// Returns a view for displaying a numbered row within a `NumberedList`.
    ///
    /// - Parameters:
    ///   - title: The title text to display in the row.
    ///   - subtitle: The subtitle text to display in the row.
    ///
    private func numberedRowView(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LocalizedStringKey(title))
                .styleGuide(.headline, weight: .semibold, includeLinePadding: false, includeLineSpacing: false)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

            Text(LocalizedStringKey(subtitle))
                .styleGuide(.subheadline)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
        }
        .padding(.vertical, 12)
        .padding(.trailing, 16) // Leading padding is handled by `NumberedList`.
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    MasterPasswordGuidanceView(store: Store(processor: StateProcessor())).navStackWrapped
}
#endif
