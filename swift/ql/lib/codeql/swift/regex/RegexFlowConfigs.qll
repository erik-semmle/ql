/**
 * Defines configurations and steps for handling regexes
 */

import swift
private import codeql.swift.dataflow.DataFlow
// TODO: This is horribly incomplete, but it's a start
private import codeql.swift.elements.expr.StringLiteralExpr

/**
 * Holds if `regex` is used as a regex, with the mode `mode` (if known).
 * If regex mode is not known, `mode` will be `"None"`.
 *
 * As an optimisation, only regexes containing an infinite repitition quatifier (`+`, `*`, or `{x,}`)
 * and therefore may be relevant for ReDoS queries are considered.
 */
predicate usedAsRegex(StringLiteralExpr regex, string mode, boolean match_full_string) {
  mode = "None" and // TODO: proper mode detection
  (if matchesFullString(regex) then match_full_string = true else match_full_string = false)
}

/**
 * Holds if `regex` is used as a regular expression that is matched against a full string,
 * as though it was implicitly surrounded by ^ and $.
 */
private predicate matchesFullString(StringLiteralExpr regex) {
  none() // TODO:
}

/**
 * Holds if the string literal `regex` is a regular expression that is matched against the expression `str`.
 *
 * As an optimisation, only regexes containing an infinite repitition quatifier (`+`, `*`, or `{x,}`)
 * and therefore may be relevant for ReDoS queries are considered.
 */
predicate regexMatchedAgainst(StringLiteralExpr regex, Expr str) {
  none() // TODO:
}
