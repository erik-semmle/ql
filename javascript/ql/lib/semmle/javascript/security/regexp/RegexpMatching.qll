/**
 * Provides predicates for reasoning about which strings are matched by a regular expression,
 * and for testing which capture groups are filled when a particular regexp matches a string.
 */

private import RegexTreeView::RegexTreeView as TreeView
private import semmle.javascript.internal.LocationsImpl::LocationsImpl as LocImpl
// RegexpMatching should be used directly from the shared pack, and not from this file.
deprecated import codeql.nfa.RegexpMatching::Make<LocImpl, TreeView> as Dep
import Dep
