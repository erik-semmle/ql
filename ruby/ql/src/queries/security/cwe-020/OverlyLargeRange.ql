/**
 * @name Overly permissive regular expression range
 * @description Overly permissive regular expression ranges match a wider range of characters than intended.
 *              This may allow an attacker to bypass a filter or sanitizer.
 * @kind problem
 * @problem.severity warning
 * @security-severity 5.0
 * @precision high
 * @id rb/overly-large-range
 * @tags correctness
 *       security
 *       external/cwe/cwe-020
 */

private import codeql.ruby.security.regexp.RegexTreeView::RegexTreeView as TreeView
import codeql.nfa.OverlyLargeRangeQuery::Make<TreeView>

RegExpCharacterClass potentialMisparsedCharClass() {
  // some escapes, e.g. [\000-\037] are currently misparsed.
  result.getAChild().(TreeView::RegExpNormalChar).getValue() = "\\"
  or
  // nested char classes are currently misparsed
  result.getAChild().(TreeView::RegExpNormalChar).getValue() = "["
}

from RegExpCharacterRange range, string reason
where
  problem(range, reason) and
  not range.getParent() = potentialMisparsedCharClass()
select range, "Suspicious character range that " + reason + "."
