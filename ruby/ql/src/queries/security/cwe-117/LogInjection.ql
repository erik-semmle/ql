/**
 * @name Log injection
 * @description Building log entries from user-controlled sources is vulnerable to
 *              insertion of forged log entries by a malicious user.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.8
 * @precision medium
 * @id rb/log-injection
 * @tags security
 *       external/cwe/cwe-117
 */

import codeql.ruby.AST
import LogInjectionConfigurationInst::PathGraph
import codeql.ruby.security.LogInjectionQuery

from LogInjectionConfigurationInst::PathNode source, LogInjectionConfigurationInst::PathNode sink
where LogInjectionConfigurationInst::flowPath(source, sink)
select sink.getNode(), source, sink, "Log entry depends on a $@.", source.getNode(),
  "user-provided value"
