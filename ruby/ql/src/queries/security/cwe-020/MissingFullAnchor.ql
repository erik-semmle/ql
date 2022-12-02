/**
 * @name Badly anchored regular expression
 * @description Regular expressions anchored using `^` or `$` are vulnerable to bypassing.
 * @kind path-problem
 * @problem.severity warning
 * @security-severity 7.8
 * @precision medium
 * @id rb/regex/badly-anchored-regexp
 * @tags correctness
 *       security
 *       external/cwe/cwe-020
 */

import codeql.ruby.DataFlow
import codeql.ruby.Regexp as RE

class RegExpTerm = RE::RegExpTerm;

/** Holds if `term` is one of the transitive left children of a regexp. */
predicate isLeftArmTerm(RegExpTerm term) {
  // TODO: shared with MissingRegExpAnchor.ql
  term.isRootTerm()
  or
  exists(RegExpTerm parent |
    term = parent.getChild(0) and
    isLeftArmTerm(parent)
  )
}

/** Holds if `term` is one of the transitive right children of a regexp. */
predicate isRightArmTerm(RegExpTerm term) {
  // TODO: shared with MissingRegExpAnchor.ql
  term.isRootTerm()
  or
  exists(RegExpTerm parent |
    term = parent.getLastChild() and
    isRightArmTerm(parent)
  )
}

RegExpTerm getABadlyAnchoredTerm() {
  exists(RegExpTerm left | left.getRootTerm() = result |
    left.(RE::RegExpAnchor).getChar() = "^" and
    isLeftArmTerm(left)
  ) and
  exists(RegExpTerm right | right.getRootTerm() = result |
    right.(RE::RegExpAnchor).getChar() = "$" and
    isRightArmTerm(right)
  )
}

/**
 * A data flow source node for polynomial regular expression denial-of-service vulnerabilities.
 */
abstract class Source extends DataFlow::Node {
  string describe() { result = "user-provided value" }
}

private import codeql.ruby.dataflow.RemoteFlowSources
private import codeql.ruby.frameworks.core.Gem::Gem as Gem

class RemoteFlowAsSource extends Source instanceof RemoteFlowSource { }

class LibrayInputAsSource extends Source {
  LibrayInputAsSource() { this = Gem::getALibraryInput() }

  override string describe() { result = "library input" }
}

class Sink extends DataFlow::Node {
  DataFlow::Node matchNode;
  RegExpTerm term;

  Sink() {
    RE::getRegexpExecution(term, this, matchNode) and
    term = getABadlyAnchoredTerm()
  }

  DataFlow::Node getCallNode() { result = matchNode }

  RegExpTerm getTerm() { result = term }
}

import codeql.ruby.TaintTracking

class Configuration extends TaintTracking::Configuration {
  Configuration() { this = "PolynomialReDoS" }

  override predicate isSource(DataFlow::Node source) { source instanceof Source }

  override predicate isSink(DataFlow::Node sink) { sink instanceof Sink }
}

import DataFlow::PathGraph

from Configuration config, DataFlow::PathNode source, DataFlow::PathNode sink, Sink sinkNode
where config.hasFlowPath(source, sink) and sink.getNode() = sinkNode
select sink, source, sink, "This value depends on $@, and is $@ against a $@.", source.getNode(),
  source.getNode().(Source).describe(), sinkNode.getCallNode(), "checked", sinkNode.getTerm(),
  "badly anchored regular expression"
