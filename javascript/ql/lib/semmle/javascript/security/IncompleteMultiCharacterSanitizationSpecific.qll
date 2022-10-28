/**
 * Provides language-specific predicates for reasoning about improper multi-character sanitization.
 */

import javascript
private import semmle.javascript.security.regexp.RegexTreeView::RegexTreeView as TreeView
private import semmle.javascript.internal.LocationsImpl::LocationsImpl as LocImpl
import codeql.nfa.NfaUtils::Make<LocImpl, TreeView> as NfaUtils

class StringSubstitutionCall = StringReplaceCall;

/**
 * A regexp term that matches substrings that should be replaced with the empty string.
 */
class EmptyReplaceRegExpTerm extends RegExpTerm {
  EmptyReplaceRegExpTerm() {
    exists(StringReplaceCall replace |
      [replace.getRawReplacement(), replace.getCallback(1).getAReturn()].mayHaveStringValue("") and
      this = replace.getRegExp().getRoot().getAChild*()
    )
  }

  /**
   * Get the substitution call that uses this regexp term.
   */
  StringSubstitutionCall getCall() { this = result.getRegExp().getRoot() }
}
