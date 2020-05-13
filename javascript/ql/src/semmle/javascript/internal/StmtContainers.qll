/**
 * INTERNAL. DO NOT IMPORT DIRECTLY.
 *
 * Provides predicates and classes for relating nodes to their
 * enclosing `StmtContainer`.
 */

private import javascript

cached
private StmtContainer getStmtContainer(NodeInStmtContainer node) {
  result =
    unique(StmtContainer container |
      exprContainers(node, container)
      or
      stmtContainers(node, container)
      or
      // Properties
      exists(ASTNode parent | properties(node, parent, _, _, _) |
        exprContainers(parent, container)
        or
        stmtContainers(parent, container)
      )
      or
      // Synthetic CFG nodes
      entry_cfg_node(node, container)
      or
      exit_cfg_node(node, container)
      or
      exists(Expr test |
        guard_node(node, _, test) and
        exprContainers(test, container)
      )
      or
      // JSDoc type annotations
      stmtContainers(node.(JSDocTypeExpr).getEnclosingStmt(), container)
    )
}

/**
 * A node that occurs inside a function or top-level or is itself a top-level.
 *
 * Specifically, this is the union type of `ControlFlowNode`, `TypeAnnotation`,
 * and `TopLevel`.
 */
class NodeInStmtContainer extends Locatable, @node_in_stmt_container {
  /**
   * Gets the function or toplevel to which this node belongs.
   */
  pragma[inline]
  final StmtContainer getContainer() { result = getStmtContainer(this) }
}
