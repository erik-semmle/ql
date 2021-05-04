/**
 * @name Unsafe HTML constructed from library input
 * @description Using externally controlled strings to construct HTML might allow a malicious
 *              user to perform an cross-site scripting attack.
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @id js/html-constructed-from-input
 * @tags security
 *       external/cwe/cwe-079
 *       external/cwe/cwe-116
 */

import javascript
import DataFlow::PathGraph

from DataFlow::PathNode source, DataFlow::PathNode sink, DataFlow::Node sinkNode
where none() and sink.getNode() = sinkNode
select sinkNode, source, sink, "$@ based on $@ might later cause $@.", sinkNode, "descrive",
  source.getNode(), "library input", sinkNode, "kind"
