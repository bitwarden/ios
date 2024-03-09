import Foundation

// MARK: - Tree

/// A model defining an array of TreeNode structures.
///
struct Tree<T: TreeNodeModel>: Equatable {
    // MARK: Parameters

    /// An array of TreeNode models.
    var rootNodes: [TreeNode<T>]

    // MARK: Initialization

    /// Initializes a Tree with a list of nodes.
    ///
    ///  - Parameter nodes: The root nodes for this structure.
    ///
    init(nodes: [TreeNode<T>]) {
        rootNodes = nodes
    }

    // MARK: Methods

    /// Searches the tree structure for a node with a specific ID.
    ///
    ///  - Parameter id: The unique identifier for the `TreeNode` object being searched for.
    ///  - Returns: A `TreeNode` object with the matching ID if found; otherwise, `nil`.
    ///
    /// The function iterates through each node in `nodeTree`. If a node with the matching ID is
    /// found, that node is returned. If not, the function recursively searches the children of
    /// each node. The search continues until the node is found or all nodes have been examined.
    ///
    /// This function allows for deep searching within a tree structure to locate a node by its
    /// unique identifier.
    ///
    func getTreeNodeObject(with id: String) -> TreeNode<T>? {
        for node in rootNodes {
            if node.node.id == id {
                return node
            } else if let childNode = Tree(nodes: node.children).getTreeNodeObject(with: id) {
                return childNode
            }
        }
        return nil
    }
}

// MARK: - TreeNode

/// A model defining a nested tree structure for a given model.
///
struct TreeNode<T: TreeNodeModel>: Equatable {
    // MARK: Properties

    /// The parent model for a given node.
    var parent: T?

    /// The name of the node.
    var name: String

    /// The current node.
    var node: T

    /// The child nodes of this model.
    var children: [TreeNode<T>]

    // MARK: Initialization

    /// Initialize a `TreeNode`.
    ///
    /// - Parameters:
    ///   - node: The current node.
    ///   - name: The name of the node.
    ///   - parent: The parent model for a given node.
    ///   - children: The child nodes of this model.
    ///
    init(
        node: T,
        name: String,
        parent: T?,
        children: [TreeNode<T>] = []
    ) {
        self.parent = parent
        self.node = node
        self.name = name
        self.children = children
    }
}

extension TreeNode {
    /// Recursively traverses a tree structure and inserts a new node based on a hierarchical path
    /// represented by `parts`.
    ///
    /// The function can either add a new node to the tree or navigate deeper into the tree
    /// structure if the current part of the path already exists.
    ///
    /// - Parameters:
    ///   - item: The `TreeNode` object to be added to the tree. This object represents the final
    ///     node to be inserted.
    ///   - nodeTree: An `inout` array of `TreeNode` objects representing the current level of the
    ///     tree structure. This array can be modified by the function to include new nodes.
    ///   - partIndex: The current index in the `parts` array that the function is processing. This
    ///     helps to keep track of the depth within the tree during recursion.
    ///   - parts: An array of strings representing the hierarchical path to the desired node
    ///     location. Each element in the array represents a level in the tree structure.
    ///   - parent: The parent node of the current recursion level. This is `nil` at the root level
    ///     and updated as the recursion delves deeper into the tree.
    ///   - delimiter: A character used to concatenate parts of the path if necessary. This is used
    ///     when adjusting the path to fit the tree's existing structure.
    /// - Returns: An updated tree.
    ///
    /// The function starts at the root level (`partIndex` = 0) and traverses down the tree
    /// following the path specified by `parts`. If a part is encountered that does not exist, and
    /// it's the last part of the path, a new node is created and added. If it's not the last part,
    /// the function attempts to merge the current and next parts and retries the insertion. This
    /// allows for flexible tree modification and growth.
    ///
    static func traverse( // swiftlint:disable:this function_parameter_count
        _ nodeTree: [TreeNode<T>],
        adding item: T,
        atIndex partIndex: Int,
        parts: [String],
        parent: T?,
        delimiter: Character
    ) -> [TreeNode<T>] {
        guard parts.count > partIndex else {
            return nodeTree
        }

        let end = partIndex == parts.count - 1
        let partName = parts[partIndex]
        var newTree = nodeTree

        if let index = newTree.firstIndex(where: { $0.name == partName }) {
            if end, newTree[index].node.id != item.id {
                newTree.append(TreeNode(node: item, name: partName, parent: parent))
            } else {
                newTree[index].children = traverse(
                    newTree[index].children,
                    adding: item,
                    atIndex: partIndex + 1,
                    parts: parts,
                    parent: newTree[index].node,
                    delimiter: delimiter
                )
            }
        } else if end {
            newTree.append(TreeNode(node: item, name: partName, parent: parent))
        } else {
            var newParts = parts
            let newPartName = "\(parts[partIndex])\(delimiter)\(parts[partIndex + 1])"
            newParts[partIndex] = newPartName
            newParts.remove(at: partIndex + 1)
            newTree = traverse(
                newTree,
                adding: item,
                atIndex: partIndex,
                parts: newParts,
                parent: parent,
                delimiter: delimiter
            )
        }
        return newTree
    }
}

// MARK: - TreeNodeModel

/// A protocol defining a model that can be used as a tree node.
///
protocol TreeNodeModel: Equatable {
    /// The unique `id` of the model.
    var id: String? { get }

    /// The name of the model
    var name: String { get }
}

// MARK: - Array

extension Array where Element: TreeNodeModel {
    /// Convert a flat array of items conforming to `TreeNodeModel` into a nested tree.
    ///
    ///  - Parameter delimiter: The character used to split the name string. The default is "/".
    ///  - Returns: A `Tree` containing the nested elements from the array.
    ///
    func asNestedNodes(
        delimiter: Character = "/"
    ) -> Tree<Element> {
        var nodes = [TreeNode<Element>]()
        for item in self {
            let delimiterSet = CharacterSet(charactersIn: String(delimiter))
            // Remove leading and trailing delimiters, then split the item name by the delimiter to
            // get the hierarchy
            let itemNameParts = item.name
                .trimmingCharacters(in: delimiterSet)
                .components(separatedBy: delimiterSet)

            nodes = TreeNode.traverse(
                nodes,
                adding: item,
                atIndex: 0,
                parts: itemNameParts,
                parent: nil,
                delimiter: delimiter
            )
        }
        return Tree(nodes: nodes)
    }
}
