// generated by codegen/codegen.py
import codeql.swift.elements.stmt.Stmt

class ReturnStmtBase extends @return_stmt, Stmt {
  override string getAPrimaryQlClass() { result = "ReturnStmt" }
}
