/**
 * The purpose of this file is to reduce the number of stages computed by the runtime,
 * thereby speeding up the evaluation a bit without changing any results.
 *
 * Computing less stages can improve performance as each stages is less likely to recompute non-cached predicates.
 *
 * A number of stages are grouped into an extended stage.
 * (Where an extended stage contains a number of substages - corrosponding to to how the stages would be grouped if this file didn't exist).
 * Each extended stage is identified by a public predicate in the `ExtendedStaging` module.
 *
 * The number of stages are reduced by abusing how the compiler groups predicates into stages.
 * The compiler decides which predicates goes into which stage by finding all strongly-connected-components (SCCs) of `cached` predicates,
 * and putting each SCC into it's own stage.
 *
 * The predicates in this file abuse this feature of the compiler by adding dependencies between the predicates in different stages.
 * By adding these dependencies some SCCs gets bigger, and thus some stages are grouped into extended stages.
 * Calls from the `cached` predicates back into the public predicates in this file are added to ensure a cyclic dependency between
 * the predicates in the extended stage.
 *
 * If there exists a negative dependency between two stages, then those stages cannot be grouped into an extended stage.
 *
 * The public predicates in this file always hold, they have no effect at runtime, and are eliminated by constant-folding in the optimizer.
 * Therefore no predicate in this file is ever evaluated by the evaluator.
 *
 * Grouping stages into extended stages can cause unnecessary computation, as a concrete query might not depend on
 * all the stages in the extended stage.
 * Care should therefore be taken not to group stages into an extended stage, if it is likely that a query only depend
 * on some but not all the stages in the extended stage.
 */

import javascript
private import internal.StmtContainers
private import semmle.javascript.dataflow.internal.PreCallGraphStep
private import semmle.javascript.dataflow.internal.FlowSteps

/**
 * Contains predicates ensuring that predicates that are supposed to be in the same stage, are in the same stage.
 * All the public predicates always hold.
 *
 * Each of the public predicates are of the following form:
 * ```CodeQL
 * predicate name() {
 *   // making sure the predicate always hold, and thus the entire predicate is eliminated by the optimizer.
 *   1 = 1
 *   or
 *   // a helper-predicate that adds dependencies from the extended stage into the `cached` predicates of each substage.
 *     nameSubstages()
 *   or
 *   // adds a negative dependency to the previous extended stage
 *   // this ensures that two extended stages can never be grouped into the same stage at runtime.
 *   not previousStage()
 * }
 * ```
 */
module ExtendedStaging {
  /**
   * The `ast` extended stage.
   * Consists of 7 substages (as of writing this).
   *
   * substage 1:
   *   AST::ASTNode::getParent
   * substage 2:
   *   JSDoc::Documentable::getDocumentation
   * substage 3:
   *   StmtContainers::getStmtContainer
   * substage 4:
   *   AST::StmtContainer::getEnclosingContainer
   * substage 5:
   *   AST::ASTNode::getTopLevel
   * substage 6:
   *   AST::isAmbientTopLevel
   * substage 7:
   *   Expr::Expr::getStringValue // maybe doesn't belong here?
   * substage 8:
   *   AST::ASTNode::isAmbientInternal
   */
  cached
  module Ast {
    cached
    predicate ref() { 1 = 1 }

    cached
    predicate backref() {
      exists(any(ASTNode a).getTopLevel())
      or
      exists(any(ASTNode a).getParent())
      or
      exists(any(StmtContainer c).getEnclosingContainer())
      or
      exists(any(Documentable d).getDocumentation())
      or
      exists(any(NodeInStmtContainer n).getContainer())
      or
      exists(any(Expr e).getStringValue())
      or
      any(ASTNode node).isAmbientInternal()
    }
  }

  /**
   * The `basicblocks` extended stage.
   * Consists of 2 substages (as of writing this).
   *
   * substage 1:
   *   BasicBlocks::Internal::bbLength#ff
   *   BasicBlocks::Internal::useAt#ffff
   *   BasicBlocks::Internal::defAt#ffff
   *   BasicBlocks::Internal::reachableBB#f
   *   BasicBlocks::Internal::bbIndex#fff
   * substage 2:
   *   BasicBlocks::bbIDominates#ff
   */
  cached
  module BasicBlocks {
    cached
    predicate ref() { 1 = 1 }

    cached
    predicate backref() {
      any(ReachableBasicBlock bb).dominates(_)
      or
      exists(any(BasicBlock bb).getNode(_))
    }
  }

  /**
   * The `dataflow` extended stage.
   * Consists of 6 substages (as of writing this).
   *
   * substage 1:
   *   SSA::Internal
   * substage 2:
   *   All the constructors in DataFlowNode.qll
   * substage 3:
   *   AMD::AmdModule
   * substage 4:
   *   DataFlow::DataFlow::localFlowStep
   * substage 5:
   *   Sources::Cached::isSyntacticMethodCall
   *   NodeJS::isRequire
   *   Sources::Cached::dynamicPropRef
   *   Sources::Cached::hasLocalSource
   *   Sources::Cached::invocation
   *   Sources::Cached::namedPropRef
   *   Sources::SourceNode::Range
   * substage 6:
   *   Expr::getCatchParameterFromStmt // maybe doesn't belong here?
   */
  cached
  module DataFlowStage {
    cached
    predicate ref() { 1 = 1 }

    cached
    predicate backref() {
      exists(AmdModule a)
      or
      DataFlow::localFlowStep(_, _)
      or
      exists(any(DataFlow::SourceNode s).getAPropertyReference("foo"))
      or
      exists(getCatchParameterFromStmt(_))
      or
      exists(DataFlow::ssaDefinitionNode(_))
    }
  }

  /**
   * The `imports` extended stage.
   * Consists of 2 substages (as of writing this).
   *
   * substage 1:
   *   Modules::Import::getImportedModule
   * substage 2:
   *   Nodes::moduleImport
   *
   * Implemented as a cached module as there is a negative dependency between the predicates.
   *
   * It would have been preferable to include these predicates in the dataflow or typetracking stage.
   * But that trips the BDD limit.
   */
  cached
  module Imports {
    cached
    predicate ref() { 1 = 1 }

    cached
    predicate backrefs() {
      exists(any(Import i).getImportedModule())
      or
      exists(DataFlow::moduleImport(_))
    }
  }

  /**
   * The `typetracking` extended stage.
   * Consists of 2 substages (as of writing this).
   *
   * substage 1:
   *   PreCallGraphStep::PreCallGraphStep::loadStep
   * substage 2:
   *   PreCallGraphStep::PreCallGraphStep::loadStoreStep
   *   PreCallGraphStep::PreCallGraphStep::storeStep
   *   PreCallGraphStep::PreCallGraphStep::step
   *   FlowSteps::CachedSteps
   *   CallGraphs::CallGraph
   *   Nodes::ClassNode::getAClassReference
   *   JSDoc::JSDocNamedTypeExpr::resolvedName
   *   TypeTracking::TypeTracker::append
   *   StepSummary::StepSummary::step
   *   Modules::Module::getAnExportedValue
   *   DataFlow::DataFlow::Node::getImmediatePredecessor
   *   VariableTypeInference::clobberedProp
   *   TypeInference::AnalyzedNode::getAValue
   *   GlobalAccessPaths::AccessPath::fromReference
   *   GlobalAccessPaths::AccessPath::fromRhs
   */
  cached
  module TypeTracking {
    cached
    predicate ref() { 1 = 1 }

    cached
    predicate backref() {
      PreCallGraphStep::loadStep(_, _, _)
      or
      basicLoadStep(_, _, _)
    }
  }

  /**
   * The `flowsteps` extended stage.
   * Consists of 2 substages (as of writing this).
   *
   * substage 1:
   *   Configuration::AdditionalFlowStep::loadStoreStep
   *   Configuration::AdditionalFlowStep::step
   *   Configuration::AdditionalFlowStep::storeStep
   *   Configuration::AdditionalFlowStep::loadStep
   * substage 2:
   *   GlobalAccessPaths::AccessPath::DominatingPaths::hasDominatingWrite
   */
  cached
  module FlowSteps {
    cached
    predicate ref() { 1 = 1 }

    cached
    predicate backref() {
      AccessPath::DominatingPaths::hasDominatingWrite(_)
      or
      any(DataFlow::AdditionalFlowStep s).step(_, _)
    }
  }

  /**
   * The `taint` extended stage.
   * Consists of 2 substages (as of writing this).
   *
   * substage 1:
   *   TaintTracking::TaintTracking::AdditionalTaintStep::step
   * substage 2:
   *   RemoteFlowSources::RemoteFlowSource
   */
  cached
  module Taint {
    cached
    predicate ref() { 1 = 1 }

    cached
    predicate backref() {
      any(TaintTracking::AdditionalTaintStep step).step(_, _)
      or
      exists(RemoteFlowSource r)
    }
  }
}
