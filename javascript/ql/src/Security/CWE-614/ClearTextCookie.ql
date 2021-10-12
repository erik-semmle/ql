/**
 * @name Clear text transmission of sensitive cookie
 * @description Sending sensitive information in a cookie without requring SSL encryption
 *              can expose the cookie to an attacker.
 * @kind problem
 * @problem.severity warning
 * @security-severity 5.0
 * @precision high
 * @id js/clear-text-cookie
 * @tags security
 *       external/cwe/cwe-614
 *       external/cwe/CWE-311
 *       external/cwe/CWE-312
 */

import javascript

from DataFlow::Node cookie
where none()
select cookie, "Sensitive cookie sent without enforcing SSL encryption"
