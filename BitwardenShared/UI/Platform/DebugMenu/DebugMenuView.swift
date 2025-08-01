import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - DebugMenuView

/// Represents the debug menu for configuring app settings and feature flags.
///
struct DebugMenuView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<DebugMenuState, DebugMenuAction, DebugMenuEffect>

    // MARK: View

    var body: some View {
        List {
            Section {
                featureFlags
            } header: {
                featureFlagSectionHeader
            }
            Section {
                errorReportSection
            } header: {
                Text("Error reports")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    store.send(.dismissTapped)
                } label: {
                    Text(Localizations.close)
                }
                .accessibilityIdentifier("close-debug")
            }
        }
        .navigationTitle("Debug Menu")
        .task {
            await store.perform(.viewAppeared)
        }
    }

    /// The error reports section.
    private var errorReportSection: some View {
        Group {
            Button {
                store.send(.generateErrorReport)
            } label: {
                Text(Localizations.generateErrorReport)
            }
            .accessibilityIdentifier("GenerateErrorReportButton")
            Button {
                store.send(.generateCrash)
            } label: {
                Text(Localizations.generateCrash)
            }
            .accessibilityIdentifier("GenerateCrashButton")
        }
    }

    /// The feature flags currently used in the app.
    private var featureFlags: some View {
        ForEach(store.state.featureFlags) { flag in
            Toggle(
                isOn: store.bindingAsync(
                    get: { _ in flag.isEnabled },
                    perform: { DebugMenuEffect.toggleFeatureFlag(flag.feature.rawValue, $0) }
                )
            ) {
                Text(flag.feature.name)
            }
            .toggleStyle(.bitwarden)
            .accessibilityIdentifier(flag.feature.rawValue)
        }
    }

    /// The header for the feature flags section.
    private var featureFlagSectionHeader: some View {
        HStack {
            Text("Feature Flags")
            Spacer()
            AsyncButton {
                await store.perform(.refreshFeatureFlags)
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .accessibilityLabel("RefreshFeatureFlagsButton")
        }
    }
}

#if DEBUG
#Preview {
    DebugMenuView(
        store: Store(
            processor: StateProcessor(
                state: .init(
                    featureFlags: [
                        .init(
                            feature: FeatureFlag(rawValue: "feature-flag"),
                            isEnabled: true
                        ),
                    ]
                )
            )
        )
    )
}
#endif
