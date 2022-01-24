/**
 * @name Sensitive cookie without SameSite restrictions
 * @description Sensitive cookies where the SameSite attribute is set to "None" can
 *              in some cases allow for Cross-site request forgery (CSRF) attacks.
 * @kind problem
 * @problem.severity warning
 * @security-severity 5.0
 * @precision medium
 * @id js/samesite-none-cookie
 * @tags security
 *       external/cwe/cwe-1275
 */

import javascript

from Expr e
where none()
select e, "Sensitive cookie with SameSite set to 'None'"
