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
    predicate test(string str, boolean ignorePrefix) {
      none() // maybe overriden in subclasses
    }

    /**
     * Same as `test(..)`, but where the `fillsCaptureGroup` afterwards tells which capture groups were filled by the regular expression.
     */
    predicate testWithGroups(string str, boolean ignorePrefix) {
      none() // maybe overriden in subclasses
    }

    /**
     * Holds if `regexp` matches `str`.
     */
    predicate matches(string str) { matches(str, _) }

    /**
     * Holds if matching `str` may fill capture group number `g`.
     * Only holds if `str` is in the `testWithGroups` predicate.
     */
    predicate fillsCaptureGroup(string str, int g) {
      exists(string groups |
        matches(str, groups) and
        g = groups.regexpFind("(?<!\\d)(\\d+)(?!\\d)", _, _).toInt()
      )
    }

    /**
     * Holds if `regexp` matches `str` while possibly matching the capture groups represented by `groups`.
     */
    private predicate matches(string str, string groups) {
      exists(State state | state = getAState(this, str.length() - 1, str, _, _, groups) |
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

  /**
   * Gets a state the regular expression `reg` is in after matching the `i`th char in `str`.
   * The regular expression is modelled as a non-determistic finite automaton,
   * the regular expression can therefore be in multiple states after matching a character.
   *
   * `groups` is a string representation of which capture groups are non empty while matching `str`.
   * `groups` is a sorted set of integers seperated by "|".
   */
  private State getAState(
    MatchedRegExp reg, int i, string str, boolean ignorePrefix, boolean includeGrouping,
    string groups
  ) {
    // start state, the -1 position before any chars have been matched
    i = -1 and
    (
      reg.test(str, ignorePrefix) and includeGrouping = false
      or
      reg.testWithGroups(str, ignorePrefix) and includeGrouping = true
    ) and
    result.getRepr().getRootTerm() = reg and
    isStartState(result) and
    groups = ""
    or
    // recursive case
    exists(string prevGroups |
      groups = computeNextGroups(prevGroups, group(result.getRepr()), includeGrouping)
    |
      exists(State prev |
        prev = getAState(reg, i - 1, str, ignorePrefix, includeGrouping, prevGroups) and
        deltaClosed(prev, getAnInputSymbolMatching(str.charAt(i)), result) and
        not (
          ignorePrefix = true and
          isStartState(prev) and
          isStartState(result)
        )
      )
      or
      // we can skip past word boundaries if the next char is a non-word char.
      exists(State separator |
        separator.getRepr() instanceof RegExpWordBoundary and
        separator = getAState(reg, i, str, ignorePrefix, includeGrouping, prevGroups) and
        after(separator.getRepr()) = result and
        str.charAt(i + 1).regexpMatch("\\W") // \W matches any non-word char.
      )
    )
  }

  /**
   * Gets the next set of groups from adding `group` to the previous set of groups `prevGroup`.
   * The result (and `prevGroups`) is a sorted set of integers seperated by `|`.
   */
  // TODO: THis is with inline and bindingset.
  bindingset[prevGroups, group]
  private string computeNextGroups(string prevGroups, int group, boolean includeGrouping) {
    includeGrouping = false and result = prevGroups and result = "" and group = group(_)
    or
    includeGrouping = true and
    (
      not group = -1 and
      (
        not prevGroups = "" and
        result = sorted(prevGroups + "|" + group.toString())
        or
        prevGroups = "" and
        result = group.toString()
      )
      or
      group = -1 and result = prevGroups
    )
  }

  /**
   * Gets a sorted version of `str`, where the integers seperated by "|" appear in sorted order.
   */
  bindingset[str]
  string sorted(string str) {
    result =
      strictconcat(int i |
        i = str.regexpFind("(?<!\\d)(\\d+)(?!\\d)", _, _).toInt() and not i = -1
      |
        i.toString(), "|" order by i
      )
  }

  /**
   * Gets the capture group number that `term` belongs to,
   * or -1 if `term` does not belong to a capture group.
   */
  int group(RegExpTerm term) {
    exists(RegExpGroup grp | grp.getNumber() = result | term.getParent*() = grp)
    or
    not exists(RegExpGroup grp | exists(grp.getNumber()) | term.getParent+() = grp) and
    result = -1
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

  override predicate testWithGroups(string str, boolean ignorePrefix) {
    ignorePrefix = true and
    str = ["<!-- foo -->", "<!-- foo --!>"]
  }

  override predicate test(string str, boolean ignorePrefix) {
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
  regexp.matches("<!-- foo --!>") and
  exists(int a, int b | not a = b |
    regexp.fillsCaptureGroup("<!-- foo -->", a) and
    // the <!-- foo --> can be ambigously parsed (matching both capture groups, and that is OK).
    regexp.fillsCaptureGroup("<!-- foo --!>", b) and
    not regexp.fillsCaptureGroup("<!-- foo --!>", a) and
    msg =
      "Comments ending with --> are matched with capture group " + a +
        " and capture groups ending with --!> are only matched with capture group " +
        strictconcat(int i | regexp.fillsCaptureGroup("<!-- foo --!>", i) | i.toString(), ", ") +
        "."
  )
  or
  regexp.matches("<!-- foo -->") and
  not regexp.matches("<!-- foo --!>") and
  not regexp.matches("<!- foo ->") and
  not regexp.matches("<foo>") and
  not regexp.matches("<script>") and
  msg = "This regular expression only matches --> and not --!> as a HTML comment end tag."
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
