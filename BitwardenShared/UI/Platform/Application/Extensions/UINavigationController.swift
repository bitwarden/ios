import UIKit

extension UINavigationController {
    /// Removes the hairline divider that's displayed between the navigation controller and its
    /// content.
    func removeHairlineDivider() {
        let appearance = navigationBar.scrollEdgeAppearance
        appearance?.shadowImage = UIImage()
        navigationBar.scrollEdgeAppearance = appearance
    }
}
