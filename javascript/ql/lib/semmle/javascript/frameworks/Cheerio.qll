/**
 * Provides a model of `cheerio`, a server-side DOM manipulation library with a jQuery-like API.
 */

import javascript
private import semmle.javascript.security.dataflow.DomBasedXssCustomizations

module Cheerio {
  /** Gets a reference to the `cheerio` function, possibly with a loaded DOM. */
  private API::Node cheerioApi() {
    result = API::moduleImport("cheerio")
    or
    result = cheerioApi().getMember(["load", "parseHTML"]).getReturn()
  }

  /** Gets a reference to the `cheerio` function, possibly with a loaded DOM. */
  DataFlow::SourceNode cheerioRef() { result = cheerioApi().getAValueReachableFromSource() }

  /**
   * A creation of `cheerio` object, a collection of virtual DOM elements
   * with an interface similar to that of a jQuery object.
   */
  class CheerioObjectCreation extends DataFlow::SourceNode instanceof CheerioObjectCreation::Range {
  }

  module CheerioObjectCreation {
    /**
     * The creation of a `cheerio` object.
     */
    abstract class Range extends DataFlow::SourceNode { }

    private class DefaultRange extends Range {
      DefaultRange() {
        this = cheerioApi().getACall()
        or
        this = cheerioApi().getAMember().getACall()
      }
    }
  }

  /**
   * Gets a reference to a `cheerio` object, a collection of virtual DOM elements
   * with an interface similar to jQuery objects.
   */
  private DataFlow::SourceNode cheerioObject() {
    result instanceof CheerioObjectCreation
    or
    // Chainable calls.
    exists(DataFlow::MethodCallNode call, string name |
      call = cheerioObjectRef().getAMethodCall(name) and
      result = call
    |
      if name = ["attr", "data", "prop", "css"]
      then call.getNumArgument() = 2
      else
        if name = ["val", "html", "text"]
        then call.getNumArgument() = 1
        else (
          name != "toString" and
          name != "toArray" and
          name != "hasClass"
        )
    )
  }

  /**
   * Gets a reference to a `cheerio` object, a collection of virtual DOM elements
   * with an interface similar to jQuery objects.
   */
  DataFlow::SourceNode cheerioObjectRef() {
    result = DataFlow::TypeTracker::MkTypeTracker<cheerioObject/0>::ref()
  }

  /**
   * A definition of a DOM attribute through `cheerio`.
   */
  class AttributeDef extends DOM::AttributeDefinition {
    DataFlow::CallNode call;

    AttributeDef() {
      this = call.asExpr() and
      call = cheerioObjectRef().getAMethodCall("attr") and
      call.getNumArgument() >= 2
    }

    override string getName() { call.getArgument(0).mayHaveStringValue(result) }

    override DataFlow::Node getValueNode() { result = call.getArgument(1) }
  }

  /**
   * An XSS sink through `cheerio`.
   */
  class XssSink extends DomBasedXss::Sink {
    XssSink() {
      exists(string name | this = cheerioObjectRef().getAMethodCall(name).getAnArgument() |
        JQuery::isMethodArgumentInterpretedAsHtml(name)
      )
    }
  }
}
