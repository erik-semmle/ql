/**
 * Classes and predicates for working with suspicious character ranges.
 */

private import regexp.RegexTreeView::RegexTreeView as TreeView
// OverlyLargeRangeQuery should be used directly from the shared pack, and not from this file.
deprecated import codeql.nfa.OverlyLargeRangeQuery::Make<TreeView> as Dep
import Dep
