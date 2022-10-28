private import semmle.javascript.security.regexp.RegexTreeView::RegexTreeView as TreeView
private import semmle.javascript.internal.LocationsImpl::LocationsImpl as LocImpl
import codeql.nfa.SuperlinearBackTracking::Make<LocImpl, TreeView>

from PolynomialBackTrackingTerm t
select t, t.getReason()
