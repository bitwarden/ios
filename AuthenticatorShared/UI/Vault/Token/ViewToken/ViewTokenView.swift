import BitwardenSdk
import SwiftUI

// MARK: - ViewTokenView

/// A view that displays the information for a token.
struct ViewTokenView: View {
    // MARK: Private Properties

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewTokenState, ViewTokenAction, ViewTokenEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    // MARK: View

    var body: some View {
        LoadingView(state: store.state.loadingState) { state in
            details(for: state)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toast(store.binding(
            get: \.toast,
            send: ViewTokenAction.toastShown
        ))
        .task {
            await store.perform(.appeared)
        }
    }

    /// The title of the view
    private var navigationTitle: String {
        Localizations.viewItem
    }

    // MARK: Private Views

    /// The details of the token.
    @ViewBuilder
    private func details(for state: TokenItemState) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                BitwardenTextValueField(title: Localizations.name, value: state.name)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("ItemRow")
                ViewTokenItemView(
                    store: store.child(
                        state: { _ in state },
                        mapAction: { $0 },
                        mapEffect: { $0 }
                    ),
                    timeProvider: timeProvider
                )
            }.padding(16)
        }.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                editToolbarButton {
                    store.send(.editPressed)
                }
            }
        }
    }
}

// MARK: Previews

#if DEBUG

#Preview("Loading") {
    NavigationView {
        ViewTokenView(
            store: Store(
                processor: StateProcessor(
                    state: ViewTokenState(
                        loadingState: .loading(nil)
                    )
                )
            ),
            timeProvider: PreviewTimeProvider(
                fixedDate: Date(timeIntervalSinceReferenceDate: 0)
            )
        )
    }
}

#Preview("Token") {
    NavigationView {
        ViewTokenView(
            store: Store(
                processor: StateProcessor(
                    state: ViewTokenState(
                        loadingState: .data(
                            TokenItemState(
                                configuration: .add,
                                name: "Example",
                                totpState: LoginTOTPState(
                                    authKeyModel: TOTPKeyModel(authenticatorKey: "ASDF")!,
                                    codeModel: TOTPCodeModel(
                                        code: "123123",
                                        codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                                        period: 30
                                    )
                                )
                            )
                        )
                    )
                )
            ),
            timeProvider: PreviewTimeProvider(
                fixedDate: Date(
                    timeIntervalSinceReferenceDate: 0
                )
            )
        )
    }
}

#endif
