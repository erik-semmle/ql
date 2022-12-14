/**
 * Provides default sources, sinks and sanitizers for reasoning about
 * missing full-anchored regular expressions, as well as extension
 * points for adding your own.
 */

private import ruby
private import codeql.ruby.dataflow.RemoteFlowSources
private import codeql.ruby.frameworks.core.Gem::Gem as Gem
private import codeql.ruby.Regexp as Regexp
private import HostnameRegexpShared as Shared

private class RegExpTerm = Regexp::RegExpTerm;

/**
 * Provides default sources, sinks and sanitizers for detecting
 * missing full-anchored regular expressions, as well as extension
 * points for adding your own.
 */
module MissingFullAnchor {
  /** A data flow source for missing full-anchored regular expressions. */
  abstract class Source extends DataFlow::Node {
    /** Gets a description of the source. */
    string describe() { result = "user-provided value" }
  }

  /** A data flow sink for missing full-anchored regular expressions. */
  abstract class Sink extends DataFlow::Node {
    /** Gets the node where the regexp computation happens. */
    abstract DataFlow::Node getCallNode();

    /** Gets the regular expression term. */
    abstract RegExpTerm getTerm();
  }

  /** A sanitizer for missing full-anchored regular expressions. */
  abstract class Sanitizer extends DataFlow::Node { }

  private class RemoteFlowAsSource extends Source instanceof RemoteFlowSource { }

  private class LibrayInputAsSource extends Source {
    LibrayInputAsSource() { this = Gem::getALibraryInput() }

    override string describe() { result = "library input" }
  }

  private RegExpTerm getABadlyAnchoredTerm() {
    exists(RegExpTerm left | left.getRootTerm() = result |
      left.(Regexp::RegExpAnchor).getChar() = "^" and
      Shared::isLeftArmTerm(left)
    ) and
    exists(RegExpTerm right | right.getRootTerm() = result |
      right.(Regexp::RegExpAnchor).getChar() = "$" and
      Shared::isRightArmTerm(right)
    )
  }

  private class DefaultSink extends Sink {
    DataFlow::Node matchNode;
    RegExpTerm term;

    DefaultSink() {
      Regexp::getRegexpExecution(term, this, matchNode) and
      term = getABadlyAnchoredTerm() and
      // looks like a sanitizer, not just input transformation
      exists(Ast::ConditionalExpr ifExpr |
        // TODO: Test unary logical operations
        [ifExpr.getCondition(), ifExpr.getCondition().(Ast::UnaryLogicalOperation).getOperand()] =
          matchNode.asExpr().getExpr() and
        ifExpr.getBranch(_).(Ast::MethodCall).getMethodName() = "raise"
      )
    }

    override DataFlow::Node getCallNode() { result = matchNode }

    override RegExpTerm getTerm() { result = term }
  }
}
