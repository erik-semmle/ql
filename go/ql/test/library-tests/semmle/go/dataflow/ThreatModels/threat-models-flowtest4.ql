/**
 * This is a dataflow test using "all" threat models.
 */

import Test
import semmle.go.dataflow.ExternalFlow
import codeql.dataflow.test.ProvenancePathGraph
import ShowProvenance<interpretModelForTest/2, ThreatModelFlow::PathNode, ThreatModelFlow::PathGraph>

from ThreatModelFlow::PathNode source, ThreatModelFlow::PathNode sink
where ThreatModelFlow::flowPath(source, sink)
select source, sink
