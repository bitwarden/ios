import UIKit

/// Helper functions and computed properties extended off the `UIView` class.
///
public extension UIView {
    /// Add a subview, constrained to the specified top, left, bottom and right margins.
    ///
    /// - Parameters:
    ///   - view: The subview to add.
    ///   - top: Optional top margin constant.
    ///   - leading: Optional leading margin constant.
    ///   - bottom: Optional bottom margin constant.
    ///   - trailing: Optional trailing margin constant.
    ///
    func addConstrained(
        subview: UIView,
        top: CGFloat? = 0,
        leading: CGFloat? = 0,
        bottom: CGFloat? = 0,
        trailing: CGFloat? = 0
    ) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)

        if let top {
            subview.topAnchor.constraint(equalTo: topAnchor, constant: top).isActive = true
        }
        if let leading {
            subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leading).isActive = true
        }
        if let bottom {
            subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottom).isActive = true
        }
        if let trailing {
            subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -trailing).isActive = true
        }
    }
}
