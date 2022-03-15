/**
 * @name Unqueryable code
 * @description Code that cannot affect the outcome of any query is suspicous.
 * @kind problem
 * @problem.severity recommendation
 * @id ql/unqueryable-code
 * @precision high
 */

import ql
import codeql_ql.style.DeadCodeQuery

from AstNode node
where node = unQueryable()
select node, "Code cannot affect the outcome of any query."
