/**
 * Provides a taint-tracking configuration for reasoning about stored
 * unsafe HTML constructed from library input vulnerabilities.
 */

import javascript

module UnsafeHtmlConstruction {
  private import semmle.javascript.security.dataflow.DomBasedXss::DomBasedXss as DomBasedXss
  import UnsafeHtmlConstructionCustomizations::UnsafeHtmlConstruction

  class Configration extends TaintTracking::Configuration {
    Configration() { this = "UnsafeHtmlConstruction" }

    override predicate isSource(DataFlow::Node source) { source instanceof Source }

    override predicate isSink(DataFlow::Node sink) { sink instanceof Sink }

    override predicate isSanitizer(DataFlow::Node node) { super.isSanitizer(node) }

    override predicate isSanitizerEdge(DataFlow::Node pred, DataFlow::Node succ) {
      DomBasedXss::isOptionallySanitizedEdge(pred, succ)
    }
  }
}
