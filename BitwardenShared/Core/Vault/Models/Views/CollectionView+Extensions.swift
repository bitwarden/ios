import BitwardenSdk
import Foundation

extension CollectionView {
    /// The default sort descriptor to use to order `CollectionView`s.
    static let defaultSortDescriptor = [
        SortDescriptorWrapper<CollectionView>(\.type.rawValue, ascending: false),
        SortDescriptorWrapper<CollectionView>(\.name, comparator: .localizedStandard),
    ]
}
