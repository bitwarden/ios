import UIKit

// MARK: - TabRepresentable

/// An object that can represent a tab in a tab navigator.
///
public protocol TabRepresentable {
    // MARK: Properties

    /// The unselected image for this tab.
    var image: UIImage? { get }

    /// The index for this tab.
    var index: Int { get }

    /// The selected image for this tab.
    var selectedImage: UIImage? { get }

    /// The title for this tab.
    var title: String { get }
}

public extension TabRepresentable where Self: RawRepresentable, Self.RawValue == Int {
    /// The index for this tab.
    var index: Int { rawValue }
}
