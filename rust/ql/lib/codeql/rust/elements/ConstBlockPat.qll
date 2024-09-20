// generated by codegen, do not edit
/**
 * This module provides the public class `ConstBlockPat`.
 */

private import internal.ConstBlockPatImpl
import codeql.rust.elements.BlockExpr
import codeql.rust.elements.Pat

/**
 * A const block pattern. For example:
 * ```rust
 * match x {
 *     const { 1 + 2 + 3 } => "ok",
 *     _ => "fail",
 * };
 * ```
 */
final class ConstBlockPat = Impl::ConstBlockPat;
