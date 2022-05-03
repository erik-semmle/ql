/**
 * @name Expression injection in Actions
 * @description Using user-controlled GitHub Actions contexts like `run:` or `script:` may allow a malicious
 *              user to inject code into the GitHub action.
 * @kind problem
 * @problem.severity warning
 * @precision medium
 * @id js/actions/injection
 * @tags actions
 *       security
 *       external/cwe/cwe-094
 */

import javascript

from Expr e
where none()
select e, "foo"
