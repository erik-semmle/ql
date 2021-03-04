/**
 * Experiment: One stage to rule them all!
 * Just compute everything that is commonly cached in a single stage. and have the query specific predicates as the second.
 */

import javascript
private import internal.StmtContainers
private import semmle.javascript.dataflow.internal.PreCallGraphStep
private import semmle.javascript.dataflow.internal.FlowSteps

/**
 * THE stage to rule them all!
 */
module ExtendedStaging {
  /**
   * THE stage to rule them all!
   */
  cached
  module TheStage {
    /**
     * THE stage to rule them all!
     */
    cached
    predicate ref() { 1 = 1 }

    /**
     * THE stage to rule them all!
     */
    cached
    predicate backrefs() {
      exists(RemoteFlowSource s)
      or
      exists(any(ASTNode s).getParent())
      or
      any(DataFlow::AdditionalFlowStep step).step(_, _)
      or
      any(ReachableBasicBlock bb).dominates(_)
      or
      AccessPath::DominatingPaths::hasDominatingWrite(_)
      or
      any(TaintTracking::AdditionalTaintStep step).step(_, _)
    }
  }
}
