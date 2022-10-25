/**
 * Provides predicates for reasoning about bad tag filter vulnerabilities.
 */

private import regexp.RegexTreeView::RegexTreeView as TreeView
private import semmle.javascript.internal.LocationsImpl::LocationsImpl as LocImpl
// BadTagFilterQuery should be used directly from the shared pack, and not from this file.
deprecated import codeql.nfa.BadTagFilterQuery::Make<LocImpl, TreeView> as Dep
import Dep
