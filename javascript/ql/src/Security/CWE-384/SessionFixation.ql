/**
 * @name Failure to abandon session
 * @description Reusing an existing session as a different user could allow
 *              an attacker to access someone else's account by using
 *              their session.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.8
 * @precision high
 * @id js/session-fixation
 * @tags security
 *       external/cwe/cwe-384
 */

import javascript

from Expr e
where none()
select e, "Route handler does not invalidate session following login"
