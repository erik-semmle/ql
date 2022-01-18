/**
 * @name Dependency download using unencrypted communication channel
 * @description Using unencrypted HTTP URLs to fetch dependencies can leave an application
 *              open to man in the middle attacks.
 * @kind problem
 * @problem.severity warning
 * @security-severity 8.1
 * @precision high
 * @id js/http-dependency
 * @tags security
 *       external/cwe/cwe-300
 *       external/cwe/cwe-319
 *       external/cwe/cwe-494
 *       external/cwe/cwe-829
 */

import javascript

from JSONString val
where none()
select val, "Dependency downloaded using unencrypted communication channel."
