/**
 * @name URL redirection from remote source
 * @description URL redirection based on unvalidated user input
 *              may cause redirection to malicious web sites.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @sub-severity low
 * @id rb/url-redirection
 * @tags security
 *       external/cwe/cwe-601
 * @precision high
 */

import codeql.ruby.AST
import codeql.ruby.security.UrlRedirectQuery
import ConfigurationInst::PathGraph

from ConfigurationInst::PathNode source, ConfigurationInst::PathNode sink
where ConfigurationInst::flowPath(source, sink)
select sink.getNode(), source, sink, "Untrusted URL redirection depends on a $@.", source.getNode(),
  "user-provided value"
