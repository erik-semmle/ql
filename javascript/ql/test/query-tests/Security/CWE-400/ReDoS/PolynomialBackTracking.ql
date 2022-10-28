private import semmle.javascript.security.regexp.RegexTreeView::RegexTreeView as TreeView
import codeql.nfa.SuperlinearBackTracking::Make<TreeView>

from PolynomialBackTrackingTerm t
select t, t.getReason()
