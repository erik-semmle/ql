// generated by codegen/codegen.py
/**
 * This module provides the generated definition of `CaseLabelItem`.
 * INTERNAL: Do not import directly.
 */

private import codeql.swift.generated.Synth
private import codeql.swift.generated.Raw
import codeql.swift.elements.AstNode
import codeql.swift.elements.expr.Expr
import codeql.swift.elements.pattern.Pattern

/**
 * INTERNAL: This module contains the fully generated definition of `CaseLabelItem` and should not
 * be referenced directly.
 */
module Generated {
  /**
   * INTERNAL: Do not reference the `Generated::CaseLabelItem` class directly.
   * Use the subclass `CaseLabelItem`, where the following predicates are available.
   */
  class CaseLabelItem extends Synth::TCaseLabelItem, AstNode {
    override string getAPrimaryQlClass() { result = "CaseLabelItem" }

    /**
     * Gets the pattern of this case label item.
     *
     * This includes nodes from the "hidden" AST. It can be overridden in subclasses to change the
     * behavior of both the `Immediate` and non-`Immediate` versions.
     */
    Pattern getImmediatePattern() {
      result =
        Synth::convertPatternFromRaw(Synth::convertCaseLabelItemToRaw(this)
              .(Raw::CaseLabelItem)
              .getPattern())
    }

    /**
     * Gets the pattern of this case label item.
     */
    final Pattern getPattern() {
      exists(Pattern immediate |
        immediate = this.getImmediatePattern() and
        result = immediate.resolve()
      )
    }

    /**
     * Gets the guard of this case label item, if it exists.
     *
     * This includes nodes from the "hidden" AST. It can be overridden in subclasses to change the
     * behavior of both the `Immediate` and non-`Immediate` versions.
     */
    Expr getImmediateGuard() {
      result =
        Synth::convertExprFromRaw(Synth::convertCaseLabelItemToRaw(this)
              .(Raw::CaseLabelItem)
              .getGuard())
    }

    /**
     * Gets the guard of this case label item, if it exists.
     */
    final Expr getGuard() {
      exists(Expr immediate |
        immediate = this.getImmediateGuard() and
        result = immediate.resolve()
      )
    }

    /**
     * Holds if `getGuard()` exists.
     */
    final predicate hasGuard() { exists(this.getGuard()) }
  }
}
