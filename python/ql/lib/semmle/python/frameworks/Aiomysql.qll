/**
 * Provides classes modeling security-relevant aspects of the `aiomysql` PyPI package.
 * See
 * - https://aiomysql.readthedocs.io/en/stable/index.html
 * - https://pypi.org/project/aiomysql/
 */

private import python
private import semmle.python.dataflow.new.DataFlow
private import semmle.python.Concepts
private import semmle.python.ApiGraphs

/** Provides models for the `aiomysql` PyPI package. */
private module Aiomysql {
  private import semmle.python.internal.Awaited

  /**
   * A `ConectionPool` is created when the result of `aiomysql.create_pool()` is awaited.
   * See https://aiomysql.readthedocs.io/en/stable/pool.html
   */
  API::Node connectionPool() {
    result = API::moduleImport("aiomysql").getMember("create_pool").getReturn().getAwaited()
  }

  /**
   * A `Connection` is created when
   * - the result of `aiomysql.connect()` is awaited.
   * - the result of calling `aquire` on a `ConnectionPool` is awaited.
   * See https://aiomysql.readthedocs.io/en/stable/connection.html#connection
   */
  API::Node connection() {
    result = API::moduleImport("aiomysql").getMember("connect").getReturn().getAwaited()
    or
    result = connectionPool().getMember("acquire").getReturn().getAwaited()
  }

  /**
   * A `Cursor` is created when
   * - the result of calling `cursor` on a `ConnectionPool` is awaited.
   * - the result of calling `cursor` on a `Connection` is awaited.
   * See https://aiomysql.readthedocs.io/en/stable/cursors.html
   */
  API::Node cursor() {
    result = connectionPool().getMember("cursor").getReturn().getAwaited()
    or
    result = connection().getMember("cursor").getReturn().getAwaited()
  }

  /**
   * Calling `execute` on a `Cursor` constructs a query.
   * See https://aiomysql.readthedocs.io/en/stable/cursors.html#Cursor.execute
   */
  class CursorExecuteCall extends SqlConstruction::Range, API::CallNode {
    CursorExecuteCall() { this = cursor().getMember("execute").getACall() }

    override DataFlow::Node getSql() { result = this.getArgument(0, "operation").getARhs() }
  }

  /**
   * Awaiting the result of calling `execute` executes the query.
   * See https://aiomysql.readthedocs.io/en/stable/cursors.html#Cursor.execute
   */
  class AwaitedCursorExecuteCall extends SqlExecution::Range {
    CursorExecuteCall executeCall;

    AwaitedCursorExecuteCall() { this = executeCall.getReturn().getAwaited().getAnImmediateUse() }

    override DataFlow::Node getSql() { result = executeCall.getSql() }
  }

  /**
   * An `Engine` is created when the result of calling `aiomysql.sa.create_engine` is awaited.
   * See https://aiomysql.readthedocs.io/en/stable/sa.html#engine
   */
  API::Node engine() {
    result =
      API::moduleImport("aiomysql")
          .getMember("sa")
          .getMember("create_engine")
          .getReturn()
          .getAwaited()
  }

  /**
   * A `SAConnection` is created when the result of calling `aquire` on an `Engine` is awaited.
   * See https://aiomysql.readthedocs.io/en/stable/sa.html#connection
   */
  API::Node saConnection() { result = engine().getMember("acquire").getReturn().getAwaited() }

  /**
   * Calling `execute` on a `SAConnection` constructs a query.
   * See https://aiomysql.readthedocs.io/en/stable/sa.html#aiomysql.sa.SAConnection.execute
   */
  class SAConnectionExecuteCall extends SqlConstruction::Range, API::CallNode {
    SAConnectionExecuteCall() { this = saConnection().getMember("execute").getACall() }

    override DataFlow::Node getSql() { result = this.getArgument(0, "query").getARhs() }
  }

  /**
   * Awaiting the result of calling `execute` executes the query.
   * See https://aiomysql.readthedocs.io/en/stable/sa.html#aiomysql.sa.SAConnection.execute
   */
  class AwaitedSAConnectionExecuteCall extends SqlExecution::Range {
    SAConnectionExecuteCall execute;

    AwaitedSAConnectionExecuteCall() { this = execute.getReturn().getAwaited().getAnImmediateUse() }

    override DataFlow::Node getSql() { result = execute.getSql() }
  }
}
