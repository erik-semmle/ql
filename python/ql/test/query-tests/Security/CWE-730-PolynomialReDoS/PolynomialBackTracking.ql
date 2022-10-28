import python
private import semmle.python.security.regexp.RegexTreeView::RegexTreeView as TreeView
import codeql.nfa.SuperlinearBackTracking::Make<TreeView>

from PolynomialBackTrackingTerm t
select t.(RegExpTerm).getRegex(), t, t.getReason()
