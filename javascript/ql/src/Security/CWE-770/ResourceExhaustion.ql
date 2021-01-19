/**
 * @name Resource exhaustion
 * @description Allocating objects or timers with user-controlled
 *              sizes or durations can cause resource exhaustion.
 * @kind path-problem
 * @problem.severity warning
 * @id js/resource-exhaustion
 * @precision high
 * @tags security
 *       external/cwe/cwe-770
 */

import javascript
import DataFlow::PathGraph

from DataFlow::PathNode source, DataFlow::PathNode sink
where none()
select sink, source, sink, "problem from $@.", source, "here"
