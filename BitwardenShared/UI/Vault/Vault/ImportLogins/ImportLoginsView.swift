import SwiftUI

// MARK: - ImportLoginsView

/// A view that instructs the user how to import their logins from another password manager.
///
struct ImportLoginsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ImportLoginsState, ImportLoginsAction, ImportLoginsEffect>

    // MARK: View

    var body: some View {
        Group {
            switch store.state.page {
            case .intro: intro()
            case .step1: step1()
            case .step2: step2()
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: store.state.page)
        .navigationBar(title: Localizations.importLogins, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
        .task {
            await store.perform(.appeared)
        }
    }

    // MARK: Private

    /// The intro page view.
    @ViewBuilder
    private func intro() -> some View {
        VStack(spacing: 32) {
            PageHeaderView(
                image: Asset.Images.import,
                title: Localizations.giveYourVaultAHeadStart,
                message: Localizations.importLoginsDescriptionLong
            )

            VStack(spacing: 12) {
                Button(Localizations.getStarted) {
                    store.send(.getStarted)
                }
                .buttonStyle(.primary())

                AsyncButton(Localizations.importLoginsLater) {
                    await store.perform(.importLoginsLater)
                }
                .buttonStyle(.transparent)
            }
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
        .scrollView()
    }

    /// The step 1 page view.
    @ViewBuilder
    private func step1() -> some View {
        stepView(step: 1, totalSteps: 3, title: Localizations.exportYourSavedLogins) {
            NumberedListRow(title: Localizations.exportLoginsStep1)
            NumberedListRow(title: Localizations.exportLoginsStep2)
            NumberedListRow(
                title: Localizations.exportLoginsStep3,
                subtitle: Localizations.exportLoginsStep3Subtitle
            )
        }
    }

    /// The step 2 page view.
    @ViewBuilder
    private func step2() -> some View {
        stepView(step: 2, totalSteps: 3, title: Localizations.logInToBitwarden) {
            NumberedListRow(title: Localizations.logInToBitwardenStep1(store.state.webVaultHost))
            NumberedListRow(title: Localizations.logInToBitwardenStep2)
        }
    }

    /// Returns a scroll view for displaying the instructions for a step.
    ///
    /// - Parameters:
    ///   - step: The step number of this page.
    ///   - totalSteps: The total number of steps.
    ///   - title: The title of the step.
    ///   - list: A closure that returns the views to display in a numbered list.
    ///
    @ViewBuilder
    private func stepView(
        step: Int,
        totalSteps: Int,
        title: String,
        @ViewBuilder list: () -> some View
    ) -> some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text(Localizations.stepXOfY(step, totalSteps))
                    .styleGuide(.subheadline, weight: .bold)

                Text(title)
                    .styleGuide(.title2, weight: .bold)
            }
            .multilineTextAlignment(.center)

            NumberedList(content: list)

            Text(LocalizedStringKey(
                Localizations.needHelpCheckOutImportHelp(ExternalLinksConstants.importHelp)
            ))
            .multilineTextAlignment(.center)
            .styleGuide(.footnote)
            .tint(Asset.Colors.textInteraction.swiftUIColor)

            VStack(spacing: 12) {
                Button(Localizations.continue) {
                    store.send(.advanceNextPage)
                }
                .buttonStyle(.primary())

                Button(Localizations.back) {
                    store.send(.advancePreviousPage)
                }
                .buttonStyle(.transparent)
            }
        }
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .frame(maxWidth: .infinity)
        .scrollView()
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Intro") {
    ImportLoginsView(store: Store(processor: StateProcessor(state: ImportLoginsState())))
        .navStackWrapped
}

#Preview("Step 1") {
    ImportLoginsView(store: Store(processor: StateProcessor(state: ImportLoginsState(page: .step1))))
        .navStackWrapped
}

#Preview("Step 2") {
    ImportLoginsView(store: Store(processor: StateProcessor(state: ImportLoginsState(page: .step2))))
        .navStackWrapped
}
#endif
