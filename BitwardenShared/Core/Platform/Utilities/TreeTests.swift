import BitwardenSdk
import XCTest

@testable import BitwardenShared

final class TreeTests: BitwardenTestCase {
    /// A test model for tree node creation.
    struct TestModel: TreeNodeModel, Equatable {
        var id: Uuid?
        var name: String
    }

    /// `getTreeNodeObject(_:)` correctly searches the tree for a given object.
    func test_getTreeNodeObject() {
        let firstOne = TestModel(id: "1", name: "first")
        let secondLayer = TestModel(id: "2", name: "/first/second/")
        let oneSlash = TestModel(id: "2", name: "uno/second")
        let thirdLayer = TestModel(id: "3", name: "first/second/third")
        let fakeSecondLayer = TestModel(id: "2.2", name: "second/dos")
        let items = [
            firstOne,
            secondLayer,
            oneSlash,
            thirdLayer,
            fakeSecondLayer,
        ]
        let nested = items.asNestedNodes()
        XCTAssertNil(nested.getTreeNodeObject(with: "4"))
        XCTAssertEqual(
            thirdLayer,
            nested.getTreeNodeObject(with: "3")?.node
        )
    }

    // `nestedNodes(_:)` organizes a flat list into a nested structure.
    func test_nestedNodes_structure() {
        let firstOne = TestModel(id: "1", name: "first")
        let secondLayer = TestModel(id: "2", name: "/first/second/")
        let oneSlash = TestModel(id: "2", name: "uno/second")
        let thirdLayer = TestModel(id: "3", name: "first/second/third")
        let fakeSecondLayer = TestModel(id: "2.2", name: "second/dos")
        let items = [
            firstOne,
            secondLayer,
            oneSlash,
            thirdLayer,
            fakeSecondLayer,
        ]
        let nested = items.asNestedNodes()
        let expectedNodes: [TreeNode<TestModel>] = [
            TreeNode(
                node: firstOne,
                name: firstOne.name,
                parent: nil,
                children: [
                    TreeNode(
                        node: secondLayer,
                        name: "second",
                        parent: firstOne,
                        children: [
                            TreeNode(
                                node: thirdLayer,
                                name: "third",
                                parent: secondLayer
                            ),
                        ]
                    ),
                ]
            ),
            TreeNode(
                node: oneSlash,
                name: oneSlash.name,
                parent: nil
            ),
            TreeNode(
                node: fakeSecondLayer,
                name: fakeSecondLayer.name,
                parent: nil
            ),
        ]
        XCTAssertEqual(nested, Tree(nodes: expectedNodes))
    }

    /// `traverseAndAdd(_:)` does nothing when the part index is out of range.
    func test_nestedTraverse_indexOutOfRange() {
        let testModelParent = TestModel(id: "parent1", name: "parent")
        let testModelExistingChild = TestModel(id: "child1", name: "child")
        let testModelNewChild = TestModel(id: "child2", name: "child")

        let nodeTree: [TreeNode<TestModel>] = [
            TreeNode(
                node: testModelParent,
                name: testModelParent.name,
                parent: nil,
                children: [
                    TreeNode(
                        node: testModelExistingChild,
                        name: testModelExistingChild.name,
                        parent: testModelParent
                    ),
                ]
            ),
        ]

        let parts = [String]()
        let newNodeTree = TreeNode.traverse(
            nodeTree,
            adding: testModelNewChild,
            atIndex: 1,
            parts: parts,
            parent: testModelParent,
            delimiter: "/"
        )
        XCTAssertEqual(
            newNodeTree,
            [
                TreeNode(
                    node: testModelParent,
                    name: testModelParent.name,
                    parent: nil,
                    children: [
                        TreeNode(
                            node: testModelExistingChild,
                            name: testModelExistingChild.name,
                            parent: testModelParent
                        ),
                    ]
                ),
            ]
        )
    }

    /// `asNestedNodes()` handles a missing branch intermediate by combining the extra parts into
    /// the final node.
    func test_nestedTraverse_missingIntermediate() {
        let first = TestModel(id: "1", name: "first")
        let firstA = TestModel(id: "1A", name: "first/a")
        let firstABC = TestModel(id: "1A", name: "first/a/b/c")

        let items = [first, firstA, firstABC]
        let nested = items.asNestedNodes()

        let expectedNodes = [
            TreeNode(
                node: first,
                name: first.name,
                parent: nil,
                children: [
                    TreeNode(
                        node: firstA,
                        name: "a",
                        parent: first,
                        children: [
                            TreeNode(node: firstABC, name: "b/c", parent: firstA),
                        ]
                    ),
                ]
            ),
        ]
        XCTAssertEqual(nested, Tree(nodes: expectedNodes))
    }

    /// `traverseAndAdd(_:)` appends a new node when no match is found.
    func test_nestedTraverse_newNode() throws {
        let testModelParent = TestModel(id: "parent1", name: "parent")
        let testModelExistingChild = TestModel(id: "child1", name: "child")
        let testModelNewChild = TestModel(id: "child2", name: "child")

        let nodeTree: [TreeNode<TestModel>] = [
            TreeNode(
                node: testModelParent,
                name: testModelParent.name,
                parent: nil,
                children: [
                    TreeNode(
                        node: testModelExistingChild,
                        name: testModelExistingChild.name,
                        parent: testModelParent
                    ),
                ]
            ),
        ]

        let parts = ["parent", "child"]
        let newNodeTree = TreeNode.traverse(
            nodeTree,
            adding: testModelNewChild,
            atIndex: 0,
            parts: parts,
            parent: testModelParent,
            delimiter: "/"
        )

        XCTAssertEqual(newNodeTree.first?.children.count, 2)
        let addedNode = try XCTUnwrap(newNodeTree.first?.children.last)
        XCTAssertEqual(addedNode.node, testModelNewChild)
    }
}
