/**
 * Provides a taint-tracking configuration for reasoning about stored
 * unsafe HTML constructed from library input vulnerabilities.
 */

import javascript

/**
 * Classes and predicates for the unsafe HTML constructed from library input query.
 */
module UnsafeHtmlConstruction {
  private import semmle.javascript.security.dataflow.DomBasedXss::DomBasedXss as DomBasedXss
  import UnsafeHtmlConstructionCustomizations::UnsafeHtmlConstruction

  /**
   * A taint-tracking configuration for reasoning about unsafe HTML constructed from library input vulnerabilities.
   */
  class Configration extends TaintTracking::Configuration {
    Configration() { this = "UnsafeHtmlConstruction" }

    override predicate isSource(DataFlow::Node source) { source instanceof Source }

    override predicate isSink(DataFlow::Node sink) { sink instanceof Sink }

    override predicate isSanitizer(DataFlow::Node node) { super.isSanitizer(node) }

    override predicate isSanitizerEdge(DataFlow::Node pred, DataFlow::Node succ) {
      DomBasedXss::isOptionallySanitizedEdge(pred, succ)
    }

    // override to require that there is a path without unmatched return steps
    override predicate hasFlowPath(DataFlow::SourcePathNode source, DataFlow::SinkPathNode sink) {
      super.hasFlowPath(source, sink) and
      requireMatchedReturn(source, sink)
    }

    override predicate isAdditionalTaintStep(DataFlow::Node pred, DataFlow::Node succ) {
      classFieldStep(pred, succ)
    }
  }
}
