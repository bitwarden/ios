import BitwardenResources
import SwiftUI

// MARK: - ExpandableHeaderView

/// A wrapper around some content which can be expanded to show the content or collapsed to hide it.
///
/// Use ``init(title:count:buttonAccessibilityIdentifier:content:)`` when the view can own its
/// own expansion state (a fresh `@State` that resets on view recreation). Use
/// ``init(title:count:buttonAccessibilityIdentifier:isExpanded:content:)`` when the caller needs
/// to persist the expanded / collapsed preference across app launches or share it across views
/// (PM-35398).
///
public struct ExpandableHeaderView<Content: View>: View {
    // MARK: Properties

    /// The accessibility identifier for the button to expand or collapse the content.
    let buttonAccessibilityIdentifier: String

    /// The content that is shown when the section is expanded or hidden otherwise.
    let content: Content

    /// A value indicating whether the expandable content is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled: Bool

    /// The title of the Header button used to expand or collapse the content.
    let title: String

    /// The count of items on the Content.
    let count: Int

    /// Expansion state ownership. When the caller supplies a `Binding<Bool>` the view writes to
    /// / reads from that binding directly; when the caller omits it, the view falls back to its
    /// own `@State`-owned storage. Keeping both storages on the struct (rather than splitting
    /// into two types) preserves the `ExpandableHeaderView(...)` initializer shape that
    /// Authenticator relies on.
    @State private var internalIsExpanded: Bool = true

    /// The caller-supplied binding, when present. `body` prefers this over `internalIsExpanded`.
    private let externalIsExpanded: Binding<Bool>?

    /// The unified binding used by `body` and `expandButton`. Resolves to `externalIsExpanded`
    /// when the caller provided one, or to `$internalIsExpanded` otherwise.
    private var isExpanded: Binding<Bool> {
        externalIsExpanded ?? $internalIsExpanded
    }

    // MARK: View

    public var body: some View {
        VStack(spacing: 8) {
            expandButton

            if isExpanded.wrappedValue {
                content
            }
        }
    }

    // MARK: Private

    /// The button to expand or collapse the content.
    @ViewBuilder private var expandButton: some View {
        Button {
            withAnimation {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                SectionHeaderView("\(title) (\(count))")

                SharedAsset.Icons.chevronDown16.swiftUIImage
                    .imageStyle(.accessoryIcon16(scaleWithFont: true))
                    .rotationEffect(isExpanded.wrappedValue ? Angle(degrees: 180) : .zero)
            }
            .multilineTextAlignment(.leading)
            .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
        }
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier(buttonAccessibilityIdentifier)
        .padding(.leading, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Initialization

    /// Initialize an `ExpandableHeaderView` whose expansion state is owned by the view itself.
    ///
    /// The view creates an internal `@State` that is reset whenever the view's identity changes.
    /// Use this initializer when the caller does not need to persist or share the expansion
    /// state.
    ///
    /// The internal state defaults to expanded (`true`). This default is part of the public
    /// contract — callers that need "collapsed by default" behavior should use
    /// ``init(title:count:buttonAccessibilityIdentifier:isExpanded:content:)`` with a
    /// pre-initialized `Binding<Bool>` set to `false`.
    ///
    /// - Important: A given call site should commit to one initializer variant. Switching
    ///   between the no-binding and binding initializer at runtime (for example, inside a
    ///   conditional branch that flips its predicate) is undefined: both initializers produce
    ///   the same ``ExpandableHeaderView`` type, so SwiftUI preserves the view's identity and
    ///   reuses the internal `@State` cell, but whichever storage is no longer populated on the
    ///   new render will be silently abandoned.
    ///
    /// - Parameters:
    ///   - title: The title of the button used to expand or collapse the content.
    ///   - count: The count of items on the Content.
    ///   - buttonAccessibilityIdentifier: The accessibility identifier for the button to expand or
    ///     collapse the content.
    ///   - content: The content that is shown when the section is expanded or hidden otherwise.
    public init(
        title: String,
        count: Int,
        buttonAccessibilityIdentifier: String = "ExpandSectionButton",
        @ViewBuilder content: () -> Content,
    ) {
        self.buttonAccessibilityIdentifier = buttonAccessibilityIdentifier
        self.content = content()
        self.title = title
        self.count = count
        externalIsExpanded = nil
    }

    /// Initialize an `ExpandableHeaderView` whose expansion state is owned by the caller.
    ///
    /// Use this initializer when the expanded / collapsed preference must survive view
    /// recreation — typically because it is persisted to a store and rehydrated on view appear
    /// (PM-35398). The caller is responsible for providing a `Binding<Bool>` whose storage
    /// outlives the view.
    ///
    /// - Important: A given call site should commit to one initializer variant. Switching
    ///   between the binding and no-binding initializer at runtime is undefined; see the
    ///   companion discussion on ``init(title:count:buttonAccessibilityIdentifier:content:)``.
    ///
    /// - Parameters:
    ///   - title: The title of the button used to expand or collapse the content.
    ///   - count: The count of items on the Content.
    ///   - buttonAccessibilityIdentifier: The accessibility identifier for the button to expand or
    ///     collapse the content.
    ///   - isExpanded: A binding that drives whether the content is currently expanded. The view
    ///     reads this value on every render and writes back through it when the user toggles
    ///     the header.
    ///   - content: The content that is shown when the section is expanded or hidden otherwise.
    public init(
        title: String,
        count: Int,
        buttonAccessibilityIdentifier: String = "ExpandSectionButton",
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content,
    ) {
        self.buttonAccessibilityIdentifier = buttonAccessibilityIdentifier
        self.content = content()
        self.title = title
        self.count = count
        externalIsExpanded = isExpanded
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17, *)
#Preview("Internal state") {
    VStack {
        ExpandableHeaderView(title: Localizations.localCodes, count: 3) {
            BitwardenTextValueField(value: "Option 1")
            BitwardenTextValueField(value: "Option 2")
            BitwardenTextValueField(value: "Option 3")
        }
    }
    .padding()
    .frame(maxHeight: .infinity, alignment: .top)
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}

@available(iOS 17, *)
#Preview("Caller-owned binding") {
    @Previewable @SwiftUI.State var isExpanded = false

    VStack {
        ExpandableHeaderView(
            title: Localizations.localCodes,
            count: 3,
            isExpanded: $isExpanded,
        ) {
            BitwardenTextValueField(value: "Option 1")
            BitwardenTextValueField(value: "Option 2")
            BitwardenTextValueField(value: "Option 3")
        }
    }
    .padding()
    .frame(maxHeight: .infinity, alignment: .top)
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
