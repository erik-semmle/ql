import javascript
import semmle.javascript.security.performance.ReDoSUtil

/**
 * A class to test whether a regular expression matches a string.
 * Override this class and extend `toTest` to configure which regular expression should be tested against which strings.
 * The result can afterwards be read from the `matches` predicate.
 */
abstract class RegexpTester extends string {
  bindingset[this]
  RegexpTester() { any() }

  /**
   * Holds if it should be tested if `regexp` matches  `str`.
   */
  abstract predicate toTest(DataFlow::RegExpCreationNode regexp, string str);

  /**
   * Gets the state a regular expression is in after matching the `i`th char if `str`.
   */
  private State getState(int i, string str) {
    i = 0 and
    exists(DataFlow::RegExpCreationNode regexp, State startState |
      toTest(regexp, str) and
      startState.getRepr().getRootTerm() = regexp.getRoot() and
      isStartState(startState) and
      deltaClosed(startState, getAnInputSymbolMatching(str.charAt(0)), result)
    )
    or
    exists(State prev |
      prev = getState(i - 1, str) and
      deltaClosed(prev, getAnInputSymbolMatching(str.charAt(i)), result)
    )
  }

  /**
   * Holds if `regexp` matches `str`.
   */
  predicate matches(DataFlow::RegExpCreationNode regexp, string str) {
    exists(State state | state = getState(str.length() - 1, str) |
      state.getRepr().getRootTerm() = regexp.getRoot() and
      epsilonSucc*(state) = Accept(_)
    )
  }
}

private predicate isStartState(State state) {
  state = mkMatch(any(RegExpRoot r)) and
  not exists(RegExpCaret car | car.getRootTerm() = state.getRepr().getRootTerm())
  or
  exists(RegExpCaret car | state = after(car))
}

class MyTester extends RegexpTester {
  MyTester() { this = "MyTester" }

  override predicate toTest(DataFlow::RegExpCreationNode regexp, string str) {
    regexp.toString() = ["/ENOENT/", "/^ref: (.*)$/"] and
    regexp.getFile().getBaseName() = "git.ts" and
    str = ["foo", "ENOENT", "f ENOENTx", "PRE ref: foo", "ref: foobar"]
  }
}

from MyTester tester, DataFlow::RegExpCreationNode regexp, string str
where tester.matches(regexp, str)
select tester, regexp, str
