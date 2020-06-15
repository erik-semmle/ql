private import python
private import DataFlowPublic

class DataFlowCall extends Call {
  /** Gets the enclosing callable of this call. */
  abstract DataFlowCallable getEnclosingCallable();
}

/** A data flow node that represents a call argument. */
abstract class ArgumentNode extends Node {
  /** Holds if this argument occurs at the given position in the given call. */
  cached
  abstract predicate argumentOf(DataFlowCall call, int pos);

  /** Gets the call in which this node is an argument. */
  final DataFlowCall getCall() { this.argumentOf(result, _) }
}


/**
 * A node associated with an object after an operation that might have
 * changed its state.
 *
 * This can be either the argument to a callable after the callable returns
 * (which might have mutated the argument), or the qualifier of a field after
 * an update to the field.
 *
 * Nodes corresponding to AST elements, for example `ExprNode`, usually refer
 * to the value before the update with the exception of `ObjectCreation`,
 * which represents the value after the constructor has run.
 */
abstract class PostUpdateNode extends Node {
  /** Gets the node before the state update. */
  abstract Node getPreUpdateNode();
}

/**
 * A return kind. A return kind describes how a value can be returned
 * from a callable.
 */
abstract class ReturnKind extends string {
  /** Gets a textual representation of this position. */
  ReturnKind() { this = "ReturnKind" }
}

/** A data flow node that represents a value returned by a callable. */
abstract class ReturnNode extends Node {
  /** Gets the kind of this return node. */
  abstract ReturnKind getKind();
}

/** A data flow node that represents the output of a call. */
abstract class OutNode extends Node {
  /** Gets the underlying call, where this node is a corresponding output of kind `kind`. */
  cached
  abstract DataFlowCall getCall(ReturnKind kind);
}

/** A node that performs a type cast. */
class CastNode extends Node {
}

class DataFlowCallable = FunctionValue;

class DataFlowExpr = Expr;

newtype TDataFlowType =
  TStringFlow()

class DataFlowType extends TDataFlowType {
  /**
   * No representation yet
   */
   string toString() { none() }
}

/** Gets a viable run-time target for the call `call`. */
DataFlowCallable viableCallable(DataFlowCall call) { none() }

/**
 * Holds if `t1` and `t2` are compatible, that is, whether data can flow from
 * a node of type `t1` to a node of type `t2`.
 */
pragma[inline]
predicate compatibleTypes(DataFlowType t1, DataFlowType t2) {
  none()
}

/**
 * This is the local flow predicate that is used as a building block in global
 * data flow. It is a strict subset of the `localFlowStep` predicate, as it
 * excludes SSA flow through instance fields.
 */
predicate simpleLocalFlowStep(Node nodeFrom, Node nodeTo) {
  none()
}

/**
 * Holds if `pred` can flow to `succ`, by jumping from one callable to
 * another. Additional steps specified by the configuration are *not*
 * taken into account.
 */
predicate jumpStep(ExprNode pred, ExprNode succ) {
  none()
}

/**
 * Holds if data can flow from `node1` to `node2` via an assignment to
 * content `c`.
 */
predicate storeStep(Node node1, Content c, Node node2) {
  none()
}

/**
 * Holds if data can flow from `node1` to `node2` via a read of content `c`.
 */
predicate readStep(Node node1, Content c, Node node2) {
  none()
}

/**
 * Gets a node that can read the value returned from `call` with return kind
 * `kind`.
 */
OutNode getAnOutNode(DataFlowCall call, ReturnKind kind) { call = result.getCall(kind) }

/**
 * Holds if the call context `ctx` reduces the set of viable run-time
 * targets of call `call` in `c`.
 */
predicate reducedViableImplInCallContext(DataFlowCall call, DataFlowCallable c, DataFlowCall ctx) {
  none()
}

/**
 * Holds if the node `n` is unreachable when the call context is `call`.
 */
predicate isUnreachableInCall(Node n, DataFlowCall call) {
  none()
}

/**
 * Holds if flow returning from callable `c` to call `call` might return
 * further and if this path restricts the set of call sites that can be
 * returned to.
 */
predicate reducedViableImplInReturn(DataFlowCallable c, DataFlowCall call) {
  none()
}

/**
 * Gets a viable run-time target for the call `call` in the context `ctx`.
 * This is restricted to those call nodes and results for which the return
 * flow from the result to `call` restricts the possible context `ctx`.
 */
DataFlowCallable prunedViableImplInCallContextReverse(DataFlowCall call, DataFlowCall ctx) {
  none()
  // result = viableImplInCallContext(call, ctx) and
  // reducedViableImplInReturn(result, call)
}

/**
 * Gets a viable run-time target for the call `call` in the context
 * `ctx`. This is restricted to those call nodes for which a context
 * might make a difference.
 */
DataFlowCallable prunedViableImplInCallContext(DataFlowCall call, DataFlowCall ctx) {
  none()
  // result = viableImplInCallContext(call, ctx) and
  // reducedViableImplInCallContext(call, _, ctx)
}

/**
 * Holds if `n` does not require a `PostUpdateNode` as it either cannot be
 * modified or its modification cannot be observed, for example if it is a
 * freshly created object that is not saved in a variable.
 *
 * This predicate is only used for consistency checks.
 */
predicate isImmutableOrUnobservable(Node n) { none() }

DataFlowType getErasedRepr(DataFlowType t) { result = t }

/** Gets a string representation of a type returned by `getErasedRepr`. */
string ppReprType(DataFlowType t) { result = t.toString() }

int accessPathLimit() { result = 3 }

/** Holds if `n` should be hidden from path explanations. */
predicate nodeIsHidden(Node n) { none() }
