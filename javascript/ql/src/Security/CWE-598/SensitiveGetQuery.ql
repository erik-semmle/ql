/**
 * @name Sensitive data read from GET request
 * @description Placing sensitive data in a GET request increases the risk of
 *              the data being exposed to an attacker.
 * @kind problem
 * @problem.severity warning
 * @security-severity 6.5
 * @precision high
 * @id js/sensitive-get-query
 * @tags security
 *       external/cwe/cwe-598
 */

import javascript

from Expr e
where none()
select e, "foo"
