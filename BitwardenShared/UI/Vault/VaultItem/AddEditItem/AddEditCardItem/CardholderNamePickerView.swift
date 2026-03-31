import BitwardenResources
import SwiftUI

// MARK: - CardholderNamePickerView

/// A modal sheet that lets the user choose a cardholder name from multiple OCR candidates.
///
struct CardholderNamePickerView: View {
    // MARK: Properties

    /// The list of candidate names detected by the card scanner.
    let candidates: [String]

    /// Called when the user taps Cancel, discarding all scanned card data.
    let onCancelled: () -> Void

    /// Called with the name the user selected.
    let onNameSelected: (String) -> Void

    /// Called when the user indicates none of the candidates match.
    let onNoneSelected: () -> Void

    /// The dismiss action for the modal sheet.
    @Environment(\.dismiss) private var dismiss

    // MARK: View

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                candidateListView
                Spacer()
            }
            .scrollView()
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea())
            .navigationTitle(Localizations.scanCard)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelToolbarItem {
                    onCancelled()
                    dismiss()
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Private Views

    /// Header showing the section title and descriptive subtitle.
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localizations.selectCardholderName)
                .styleGuide(.title2, weight: .bold)
            Text(Localizations.weFoundMultipleMatchesChooseTheCorrectOne)
                .styleGuide(.subheadline)
                .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    /// The list of selectable cardholder name candidates.
    private var candidateListView: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            ForEach(candidates, id: \.self) { name in
                Button {
                    onNameSelected(name)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(name)
                            .styleGuide(.body)
                            .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                Divider()
                    .padding(.leading, 16)
            }
            Button {
                onNoneSelected()
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Text(Localizations.noneOfTheAbove)
                        .styleGuide(.body)
                        .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            Divider()
                .padding(.leading, 16)
        }
        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Cardholder Name Picker") {
    CardholderNamePickerView(
        candidates: ["J Smith", "John Smith", "VISA PLATINUM"],
        onCancelled: {},
        onNameSelected: { _ in },
        onNoneSelected: {},
    )
}
#endif
