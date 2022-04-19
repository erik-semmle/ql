/**
 * @name Missing origin verification in `postMessage` handler
 * @description Missing origin verification in a `postMessage` handler allows any windows to send arbitrary data to the handler.
 * @kind problem
 * @problem.severity warning
 * @security-severity 5
 * @precision medium
 * @id js/missing-origin-check
 * @tags correctness
 *       security
 *       external/cwe/cwe-020
 */

import javascript

from DataFlow::Node handler
where none()
select handler, "foo"
