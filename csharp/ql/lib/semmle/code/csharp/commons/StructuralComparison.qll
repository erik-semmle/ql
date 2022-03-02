/**
 * Provides functionality for performing structural comparison of
 * expressions and statements.
 */

import csharp

abstract private class GvnKind extends TGvnKind {
  abstract string toString();
}

private class GvnKindExpr extends GvnKind, TGvnKindExpr {
  private int kind;

  GvnKindExpr() { this = TGvnKindExpr(kind) }

  override string toString() { result = "Expr(" + kind.toString() + ")" }
}

private class GvnKindStmt extends GvnKind, TGvnKindStmt {
  private int kind;

  GvnKindStmt() { this = TGvnKindStmt(kind) }

  override string toString() { result = "Stmt(" + kind.toString() + ")" }
}

private class GvnKindDeclaration extends GvnKind, TGvnKindDeclaration {
  private int kind;
  private boolean isTargetThis;
  private Declaration d;

  GvnKindDeclaration() { this = TGvnKindDeclaration(kind, isTargetThis, d) }

  override string toString() {
    result = "Expr(" + kind.toString() + ")," + isTargetThis + "," + d.toString()
  }
}

/** Gets the declaration referenced by the expression `e`, if any. */
private Declaration referenceAttribute(Expr e) {
  result = e.(MethodCall).getTarget()
  or
  result = e.(ObjectCreation).getTarget()
  or
  result = e.(Access).getTarget()
}

/** Returns true iff the target of the expression `e` is `this`. */
private boolean isTargetThis(Expr e) {
  result = true and e.(MemberAccess).targetIsThisInstance()
  or
  result = false and not e.(MemberAccess).targetIsThisInstance()
}

/** Gets the AST node kind of element `cfe` wrapped in the `GvnKind` type. */
private GvnKind getKind(ControlFlowElement cfe) {
  exists(int kind |
    expressions(cfe, kind, _) and
    result = TGvnKindExpr(kind)
    or
    statements(cfe, kind) and
    result = TGvnKindStmt(kind)
  )
}

/** The global value number of a control flow element. */
abstract class Gvn extends TGvn {
  /** Gets the string representation of this global value number. */
  abstract string toString();
}

private class ConstantGvn extends Gvn, TConstantGvn {
  override string toString() { this = TConstantGvn(result) }
}

private class GvnBase extends Gvn, TGvnBase {
  private GvnKind kind;

  GvnBase() { this = TGvnBase(kind) }

  override string toString() { result = "(kind:" + kind + ")" }
}

private class GvnStruct extends Gvn, TGvnStruct {
  private Gvn head;
  private Gvn tail;

  GvnStruct() { this = TGvnStruct(head, tail) }

  override string toString() { result = "(" + head.toString() + " :: " + tail.toString() + ")" }
}

pragma[noinline]
private predicate gvnKindDeclaration(
  ControlFlowElement cfe, int kind, boolean isTargetThis, Declaration d
) {
  isTargetThis = isTargetThis(cfe) and
  d = referenceAttribute(cfe) and
  expressions(cfe, kind, _)
}

/**
 * Gets the `GvnKind` of the element `cfe`.
 * In case `cfe` is a reference attribute, we encode the entire declaration and whether
 * the target is semantically equivalent to `this`.
 */
private GvnKind getGvnKind(ControlFlowElement cfe) {
  exists(int kind, boolean isTargetThis, Declaration d |
    gvnKindDeclaration(cfe, kind, isTargetThis, d) and
    result = TGvnKindDeclaration(kind, isTargetThis, d)
  )
  or
  not exists(referenceAttribute(cfe)) and
  result = getKind(cfe)
}

private Gvn gvnConstructed(ControlFlowElement cfe, GvnKind kind, int index) {
  kind = getGvnKind(cfe) and
  result = TGvnBase(kind) and
  index = -1
  or
  exists(Gvn head, Gvn tail |
    gvnConstructedStruct(cfe, kind, index, head, tail) and
    result = TGvnStruct(head, tail)
  )
}

private int getNumberOfActualChildren(ControlFlowElement cfe) {
  if cfe.(MemberAccess).targetIsThisInstance()
  then result = cfe.getNumberOfChildren() - 1
  else result = cfe.getNumberOfChildren()
}

private ControlFlowElement getRankedChild(ControlFlowElement cfe, int rnk) {
  result =
    rank[rnk + 1](ControlFlowElement child, int j |
      child = cfe.getChild(j) and
      (
        j >= 0
        or
        j = -1 and not cfe.(MemberAccess).targetIsThisInstance()
      )
    |
      child order by j
    )
}

pragma[noinline]
private Gvn gvnChild(ControlFlowElement cfe, int index) {
  result = toGvn(getRankedChild(cfe, index))
}

pragma[noinline]
private predicate gvnConstructedStruct(
  ControlFlowElement cfe, GvnKind kind, int index, Gvn head, Gvn tail
) {
  tail = gvnConstructed(cfe, kind, index - 1) and
  head = gvnChild(cfe, index)
}

cached
private module Cached {
  cached
  newtype TGvnKind =
    TGvnKindExpr(int kind) { expressions(_, kind, _) } or
    TGvnKindStmt(int kind) { statements(_, kind) } or
    TGvnKindDeclaration(int kind, boolean thisTarget, Declaration d) {
      exists(Expr e |
        d = referenceAttribute(e) and thisTarget = isTargetThis(e) and expressions(e, kind, _)
      )
    }

  /**
   * Type for containing the global value number of a control flow element.
   * A global value number, can either be a constant, a kind or a structure containing multiple global value numbers.
   * The construction of the type produces a list like structure.
   */
  cached
  newtype TGvn =
    TConstantGvn(string s) { s = any(Expr e).getValue() } or
    TGvnBase(GvnKind gkind) or
    TGvnStruct(Gvn head, Gvn tail) { gvnConstructedStruct(_, _, _, head, tail) }
}

private import Cached

/** Gets the global value number of the element `cfe` */
cached
Gvn toGvn(ControlFlowElement cfe) {
  result = TConstantGvn(cfe.(Expr).getValue())
  or
  not exists(cfe.(Expr).getValue()) and
  exists(GvnKind kind, int index |
    result = gvnConstructed(cfe, kind, index - 1) and
    index = getNumberOfActualChildren(cfe)
  )
}

/**
 * A configuration for performing structural comparisons of program elements
 * (expressions and statements).
 *
 * The predicate `candidate()` must be overridden, in order to identify the
 * elements for which to perform structural comparison.
 *
 * Each use of the library is identified by a unique string value.
 */
abstract class StructuralComparisonConfiguration extends string {
  bindingset[this]
  StructuralComparisonConfiguration() { any() }

  /**
   * Holds if elements `x` and `y` are candidates for testing structural
   * equality.
   *
   * Subclasses are expected to override this predicate to identify the
   * top-level elements which they want to compare. Care should be
   * taken to avoid identifying too many pairs of elements, as in general
   * there are very many structurally equal subtrees in a program, and
   * in order to keep the computation feasible we must focus attention.
   *
   * Note that this relation is not expected to be symmetric -- it's
   * fine to include a pair `(x, y)` but not `(y, x)`.
   * In fact, not including the symmetrically implied fact will save
   * half the computation time on the structural comparison.
   */
  abstract predicate candidate(ControlFlowElement x, ControlFlowElement y);

  pragma[inline]
  private predicate sameGvn(ControlFlowElement x, ControlFlowElement y) {
    pragma[only_bind_into](toGvn(pragma[only_bind_out](x))) =
      pragma[only_bind_into](toGvn(pragma[only_bind_out](y)))
  }

  /**
   * Holds if elements `x` and `y` structurally equal. `x` and `y` must be
   * flagged as candidates for structural equality, that is,
   * `candidate(x, y)` must hold.
   */
  predicate same(ControlFlowElement x, ControlFlowElement y) { candidate(x, y) and sameGvn(x, y) }
}

/**
 * INTERNAL: Do not use.
 *
 * A verbatim copy of the class `StructuralComparisonConfiguration` for internal
 * use.
 *
 * A copy is needed in order to use structural comparison within the standard
 * library without running into caching issues.
 */
module Internal {
  // Import all uses of the internal library to make sure caching works
  private import semmle.code.csharp.controlflow.Guards as G

  /**
   * A configuration for performing structural comparisons of program elements
   * (expressions and statements).
   *
   * The predicate `candidate()` must be overridden, in order to identify the
   * elements for which to perform structural comparison.
   *
   * Each use of the library is identified by a unique string value.
   */
  abstract class InternalStructuralComparisonConfiguration extends string {
    bindingset[this]
    InternalStructuralComparisonConfiguration() { any() }

    /**
     * Holds if elements `x` and `y` are candidates for testing structural
     * equality.
     *
     * Subclasses are expected to override this predicate to identify the
     * top-level elements which they want to compare. Care should be
     * taken to avoid identifying too many pairs of elements, as in general
     * there are very many structurally equal subtrees in a program, and
     * in order to keep the computation feasible we must focus attention.
     *
     * Note that this relation is not expected to be symmetric -- it's
     * fine to include a pair `(x, y)` but not `(y, x)`.
     * In fact, not including the symmetrically implied fact will save
     * half the computation time on the structural comparison.
     */
    abstract predicate candidate(ControlFlowElement x, ControlFlowElement y);

    pragma[inline]
    private predicate sameGvn(ControlFlowElement x, ControlFlowElement y) {
      pragma[only_bind_into](toGvn(pragma[only_bind_out](x))) =
        pragma[only_bind_into](toGvn(pragma[only_bind_out](y)))
    }

    /**
     * Holds if elements `x` and `y` structurally equal. `x` and `y` must be
     * flagged as candidates for structural equality, that is,
     * `candidate(x, y)` must hold.
     */
    predicate same(ControlFlowElement x, ControlFlowElement y) { candidate(x, y) and sameGvn(x, y) }
  }
}
