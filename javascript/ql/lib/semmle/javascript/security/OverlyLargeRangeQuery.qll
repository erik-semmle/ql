/**
 * Classes and predicates for working with suspicious character ranges.
 */

private import regexp.RegexTreeView::RegexTreeView as TreeView
private import semmle.javascript.internal.LocationsImpl::LocationsImpl as LocImpl
// OverlyLargeRangeQuery should be used directly from the shared pack, and not from this file.
deprecated import codeql.nfa.OverlyLargeRangeQuery::Make<LocImpl, TreeView> as Dep
import Dep
