import BitwardenSdk
import SwiftUI

// MARK: - ViewItemView

/// A view that displays the contents of a vault item.
struct ViewItemView: View {
    // MARK: Private Properties

    /// An environment variable used to open URLs.
    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewItemState, ViewItemAction, Void>

    var body: some View {
        contents
            .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
            .navigationTitle(Localizations.viewItem)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.morePressed)
                    } label: {
                        Asset.Images.verticalKabob.swiftUIImage
                            .resizable()
                            .frame(width: 19, height: 19)
                    }
                    .accessibilityLabel(Localizations.options)

                    Button {
                        store.send(.dismissPressed)
                    } label: {
                        Asset.Images.cancel.swiftUIImage
                            .resizable()
                            .frame(width: 19, height: 19)
                    }
                    .accessibilityLabel(Localizations.close)
                }
            }
    }

    /// The contents of the view, so that modifiers can be added to the entire hierarchy.
    @ViewBuilder private var contents: some View {
        switch store.state.typeState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .login:
            details
        }
    }

    /// The details of the item. This view wraps all of the different detail views for
    /// the different types of items into one variable, so that the edit button can be
    /// added to all of them at once.
    @ViewBuilder private var details: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                switch store.state.typeState {
                case let .login(loginState):
                    ViewLoginItemView(store: store.child(
                        state: { state in
                            switch state.typeState {
                            case let .login(state):
                                return state
                            default:
                                return loginState
                            }
                        },
                        mapAction: { $0 },
                        mapEffect: nil
                    ))
                case .loading:
                    EmptyView()
                }
            }
            .padding(16)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Localizations.edit) {
                    store.send(.editPressed)
                }
            }
        }
    }
}

// MARK: Previews

#if DEBUG
struct ViewItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ViewItemView(
                store: Store(
                    processor: StateProcessor(
                        state: ViewItemState(
                            typeState: .loading
                        )
                    )
                )
            )
        }
        .previewDisplayName("Loading")

        NavigationView {
            ViewItemView(
                store: Store(
                    processor: StateProcessor(
                        state: ViewItemState(
                            typeState: .login(.init(
                                customFields: [
                                    FieldView(
                                        name: "Field Name",
                                        value: "Value",
                                        type: .text,
                                        linkedId: nil
                                    ),
                                ],
                                folder: "Folder",
                                isPasswordVisible: false,
                                name: "Example",
                                notes: "This is a long note so that it goes to the next line!",
                                password: "Password1!",
                                updatedDate: Date(),
                                uris: [
                                    LoginUriView(
                                        uri: "https://www.example.com",
                                        match: .startsWith
                                    ),
                                    LoginUriView(
                                        uri: "https://www.example.com/account/login",
                                        match: .exact
                                    ),
                                ],
                                username: "email@example.com"
                            ))
                        )
                    )
                )
            )
        }
        .previewDisplayName("Login")
    }
}
#endif
