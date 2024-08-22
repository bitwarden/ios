import SwiftUI

// MARK: - ForEachIndexed

/// A Wrapper around `ForEach` to provide the index of each item to the Content.
///  Attributed to https://stackoverflow.com/a/61149111 .
///
public struct ForEachIndexed<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    // MARK: Properties

    /// The `RandomAccessCollection` data.
    public var data: Data

    /// A closure to convert the `Data.Element` into `Content`.
    ///
    /// - Parameters:
    ///   - index: The index of an element.
    ///   - element: The element.
    /// - Returns: A view constructed with `index` and `element`.
    ///
    public var content: (_ index: Data.Index, _ element: Data.Element) -> Content

    /// A Key Path id for the wrapped `ForEach`.
    var id: KeyPath<Data.Element, ID>

    public var body: some View {
        ForEach(
            zip(data.indices, data).map { index, element in
                IndexInfo(
                    index: index,
                    id: id,
                    element: element
                )
            },
            id: \.elementID
        ) { indexInfo in
            content(indexInfo.index, indexInfo.element)
        }
    }

    // MARK: Initialization

    /// Creates a `ForEach` that includes the index of each element in the `Content` construction.
    ///
    /// - Parameters:
    ///   - data: The `RandomAccessCollection`.
    ///   - id: The KeyPath pair of element and id.
    ///   - content: A closure to convert the `Data.Element` into `Content` including the `index` as a parameter.
    ///
    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        content: @escaping (_ index: Data.Index, _ element: Data.Element) -> Content
    ) {
        self.data = data
        self.id = id
        self.content = content
    }
}

/// An extension on `ForEachIndexed` to allow for an init based on `RandomAccessCollection.Element.ID`.
///
public extension ForEachIndexed where ID == Data.Element.ID, Content: View, Data.Element: Identifiable {
    // MARK: Initialization

    /// Initializes a `ForEachIndexed` based on the id of each data element.
    ///
    /// - Parameters:
    ///   - data: A `RandomAccessCollection` where `Data.Element: Identifiable`.
    ///   - content: A closure with the input of `(index, element)` that returns `Content`.
    init(_ data: Data, @ViewBuilder content: @escaping (_ index: Data.Index, _ element: Data.Element) -> Content) {
        self.init(data, id: \.id, content: content)
    }
}

extension ForEachIndexed: DynamicViewContent where Content: View {}

/// A helper to provide an item id to `ForEachIndexed` to build a `ForEach`.
///
private struct IndexInfo<Index, Element, ID: Hashable>: Hashable {
    // MARK: Properties

    /// The index of the Element.
    let index: Index

    /// The KeyPath id for an Element.
    let id: KeyPath<Element, ID>

    /// The Element.
    let element: Element

    /// Computes the id of the Element by Key Path
    var elementID: ID {
        element[keyPath: id]
    }

    // MARK: Static Methods

    /// Equatable conformance for `IndexInfo`.
    ///
    /// - Parameters:
    ///   - lhs: The left side of the comparison.
    ///   - rhs: The right side of the comparison.
    /// - Returns: A bool indicating if the two elements are equal.
    ///
    static func == (_ lhs: IndexInfo, _ rhs: IndexInfo) -> Bool {
        lhs.elementID == rhs.elementID
    }

    // MARK: Methods

    /// Hashable conformance for `IndexInfo`.
    ///
    /// - Parameter hasher: The hasher into which the elementID is hashed.
    /// - Returns: The supplied Hasher with the elementID included.
    ///
    func hash(into hasher: inout Hasher) {
        elementID.hash(into: &hasher)
    }
}
