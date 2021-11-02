/**
 * @name Use of a weak cryptographic key
 * @description Using a weak cryptographic key can allow an attacker to compromise security.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision high
 * @id js/insufficient-key-size
 * @tags security
 *       external/cwe/cwe-326
 */

import javascript

from DataFlow::Node key
where none()
select key, "foobar"
