/**
 * Provides precicates for reasoning about bad tag filter vulnerabilities.
 */

import performance.ReDoSUtil

/**
 * A module for determining if a regexp matches a given string.
 */
private module RegexpMatching {
  /**
   * A class to test whether a regular expression matches a string.
   * Override this class and extend `toTest` to configure which strings should be tested for acceptance by this regular expression.
   * The result can afterwards be read from the `matches` predicate.
   */
  abstract class MatchedRegExp extends RegExpTerm {
    MatchedRegExp() { this.isRootTerm() }

    /**
     * Holds if it should be tested whether this regular expression matches `str`.
     *
     * If `ignorePrefix` is true, then a regexp without a start anchor will be treated as if it had a start anchor.
     * E.g. a regular expression `/foo$/` will match any string that ends with "foo",
     * but if `ignorePrefix` is true, it will only match "foo".
     */
    abstract predicate toTest(string str, boolean ignorePrefix);

    /**
     * Gets a state a regular expression is in after matching the `i`th char in `str`.
     * The regular expression is modelled as a non-determistic finite automaton,
     * the regular expression can therefore be in multiple states after matching a character.
     */
    private State getAState(int i, string str, boolean ignorePrefix) {
      i = -1 and
      this.toTest(str, ignorePrefix) and
      result.getRepr().getRootTerm() = this and
      isStartState(result)
      or
      exists(State prev |
        prev = getAState(i - 1, str, ignorePrefix) and
        deltaClosed(prev, getAnInputSymbolMatching(str.charAt(i)), result) and
        not (
          ignorePrefix = true and
          isStartState(prev) and
          isStartState(result)
        )
      )
    }

    /**
     * Holds if `regexp` matches `str`.
     */
    predicate matches(string str) {
      exists(State state | state = getAState(str.length() - 1, str, _) |
        epsilonSucc*(state) = Accept(_)
      )
    }
  }

  /**
   * Holds if `state` is a start state.
   */
  private predicate isStartState(State state) {
    state = mkMatch(any(RegExpRoot r)) and
    not exists(RegExpCaret car | car.getRootTerm() = state.getRepr().getRootTerm())
    or
    exists(RegExpCaret car | state = after(car))
  }
}

/**
 * A class to test whether a regular expression matches certain HTML tags.
 */
class HTMLMatchingRegExp extends RegexpMatching::MatchedRegExp {
  HTMLMatchingRegExp() {
    // the regexp must mention "<" and ">" explicitly.
    forall(string angleBracket | angleBracket = ["<", ">"] |
      any(RegExpConstant term | term.getValue().regexpMatch(".*" + angleBracket + ".*"))
          .getRootTerm() = this
    )
  }

  override predicate toTest(string str, boolean ignorePrefix) {
    ignorePrefix = true and
    str =
      [
        "<!-- foo -->", "<!- foo ->", "<!-- foo --!>", "<!-- foo\n -->", "<script>foo</script>",
        "<script \n>foo</script>", "<script >foo\n</script>", "<foo ></foo>", "<foo>",
        "<foo src=\"foo\"></foo>", "<script>", "<script src=\"foo\"></script>",
        "<script src='foo'></script>", "<SCRIPT>foo</SCRIPT>", "<script\tsrc=\"foo\"/>",
        "<script\tsrc='foo'></script>", "<sCrIpT>foo</ScRiPt>", "<script src=\"foo\">foo</script >",
        "<script src=\"foo\">foo</script foo=\"bar\">", "<script src=\"foo\">foo</script\t\n bar>",
        "<script src=\"foo\">foo</script bar>"
      ]
  }
}

/**
 * Holds if `regexp` matches some HTML tags, but misses some HTML tags that it should match.
 *
 * When adding a new case to this predicate, make sure the test string used in `matches(..)` calls are present in `HTMLMatchingRegExp::toTest`.
 */
predicate isBadRegexpFilter(HTMLMatchingRegExp regexp, string msg) {
  regexp.matches("<!-- foo -->") and
  not regexp.matches("<!-- foo --!>") and
  not regexp.matches("<!- foo ->") and
  not regexp.matches("<foo>") and
  not regexp.matches("<script>") and
  msg = "This regular expression only matches -->  and not --!> as a HTML comment end tag."
  or
  regexp.matches("<!-- foo -->") and
  not regexp.matches("<!-- foo\n -->") and
  not regexp.matches("<!- foo ->") and
  not regexp.matches("<foo>") and
  not regexp.matches("<script>") and
  msg = "This regular expression does not match comments containing newlines."
  or
  regexp.matches("<script>foo</script>") and
  regexp.matches("<script src=\"foo\"></script>") and
  not regexp.matches("<foo ></foo>") and
  (
    not regexp.matches("<script \n>foo</script>") and
    msg = "This regular expression matches <script></script>, but not <script \\n></script>"
    or
    not regexp.matches("<script >foo\n</script>") and
    msg = "This regular expression matches <script>foo</script>, but not <script >foo\\n</script>"
  )
  or
  regexp.matches("<script src=\"foo\"></script>") and
  not regexp.matches("<script src='foo'></script>") and
  not regexp.matches("<foo>") and
  msg = "This regular expression does not match script tags where the attribute uses single-quotes."
  or
  regexp.matches("<script src='foo'></script>") and
  not regexp.matches("<script src=\"foo\"></script>") and
  not regexp.matches("<foo>") and
  msg = "This regular expression does not match script tags where the attribute uses double-quotes."
  or
  regexp.matches("<script src='foo'></script>") and
  not regexp.matches("<script\tsrc='foo'></script>") and
  not regexp.matches("<foo>") and
  not regexp.matches("<foo src=\"foo\"></foo>") and
  msg = "This regular expression does not match script tags tabs are used between attributes."
  or
  regexp.matches("<script>foo</script>") and
  not RegExpFlags::isIgnoreCase(regexp) and
  not regexp.matches("<foo>") and
  not regexp.matches("<foo ></foo>") and
  (
    not regexp.matches("<SCRIPT>foo</SCRIPT>") and
    msg = "This regular expression does not match upper case <SCRIPT> tags."
    or
    not regexp.matches("<sCrIpT>foo</ScRiPt>") and
    regexp.matches("<SCRIPT>foo</SCRIPT>") and
    msg = "This regular expression does not match mixed case <sCrIpT> tags."
  )
  or
  regexp.matches("<script src=\"foo\"></script>") and
  not regexp.matches("<foo>") and
  not regexp.matches("<foo ></foo>") and
  (
    not regexp.matches("<script src=\"foo\">foo</script >") and
    msg = "This regular expression does not match script end tags like </script >."
    or
    not regexp.matches("<script src=\"foo\">foo</script foo=\"bar\">") and
    msg = "This regular expression does not match script end tags like </script foo=\"bar\">."
    or
    not regexp.matches("<script src=\"foo\">foo</script bar>") and
    msg = "This regular expression does not match script end tags like </script bar>."
    or
    not regexp.matches("<script src=\"foo\">foo</script\t\n bar>") and
    msg = "This regular expression does not match script end tags like </script\\t\\n bar>."
  )
}
