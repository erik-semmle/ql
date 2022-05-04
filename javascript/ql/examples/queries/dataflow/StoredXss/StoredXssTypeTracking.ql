/**
 * @name Extension of standard query: Stored XSS (with TrackedNode)
 * @description Extends the standard Stored XSS query with an additional source,
 *              using TrackedNode to track MySQL connections globally.
 * @kind path-problem
 * @problem.severity error
 * @tags security
 * @id js/examples/stored-xss-trackednode
 */

import javascript
import semmle.javascript.security.dataflow.StoredXssQuery
import DataFlow::PathGraph

/**
 * Gets a call to `mysql.createConnection()`.
 */
DataFlow::SourceNode mysqlConnection() {
  result = DataFlow::moduleImport("mysql").getAMemberCall("createConnection")
}

/**
 * The data returned from a MySQL query.
 *
 * For example:
 * ```
 * let mysql = require('mysql');
 *
 * getData(mysql.createConnection());
 *
 * function getData(c) {
 *   c.query(..., (e, data) => { ... });
 * }
 * ```
 */
class MysqlSource extends Source {
  MysqlSource() {
    this =
      DataFlow::TypeTracker::MkTypeTracker<mysqlConnection/0>::ref()
          .getAMethodCall("query")
          .getCallback(1)
          .getParameter(1)
  }
}

from Configuration cfg, DataFlow::PathNode source, DataFlow::PathNode sink
where cfg.hasFlowPath(source, sink)
select sink.getNode(), source, sink, "Stored XSS from $@.", source.getNode(), "database value."
