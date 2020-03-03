/**
 * Provides default sources for reasoning about DOM-based
 * cross-site scripting vulnerabilities.
 */

import javascript

module DomBasedXss {
  import Xss::DomBasedXss

  /** A source of remote user input, considered as a flow source for DOM-based XSS. */
  class RemoteFlowSourceAsSource extends Source {
    RemoteFlowSourceAsSource() { this instanceof RemoteFlowSource }
  }

  /**
   * An access of the URL of this page, or of the referrer to this page.
   */
  class LocationSource extends Source {
    LocationSource() { this = DOM::locationSource() }
  }

  /**
   * A read of the `value` property from a DOM node.
   *
   * For example:
   * ```
   * var input = document.createElement("input");
   * insertIntoDOM(input, function () {
   *   var color = input.value; // <- source
   * });
   *
   * ```
   */
  class DOMValuePropertyAsSource extends Source {
    DOMValuePropertyAsSource() { 
      this = DOM::domValueSource().getAPropertyRead("value") or 
      exists(JQuery::MethodCall call | this = call |
        call.getMethodName() = "val" and
        not exists(call.getAnArgument())
      )
    }
  }
}
