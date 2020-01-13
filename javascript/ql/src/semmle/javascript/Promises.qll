/**
 * Provides classes for modelling promises and their data-flow.
 */

import javascript

/**
 * A definition of a `Promise` object.
 */
abstract class PromiseDefinition extends DataFlow::SourceNode {
  /** Gets the executor function of this promise object. */
  abstract DataFlow::FunctionNode getExecutor();

  /** Gets the `resolve` parameter of the executor function. */
  DataFlow::ParameterNode getResolveParameter() { result = getExecutor().getParameter(0) }

  /** Gets the `reject` parameter of the executor function. */
  DataFlow::ParameterNode getRejectParameter() { result = getExecutor().getParameter(1) }

  /** Gets the `i`th callback handler installed by method `m`. */
  private DataFlow::FunctionNode getAHandler(string m, int i) {
    result = getAMethodCall(m).getCallback(i)
  }

  /**
   * Gets a function that handles promise resolution, including both
   * `then` handlers and `finally` handlers.
   */
  DataFlow::FunctionNode getAResolveHandler() {
    result = getAHandler("then", 0) or
    result = getAFinallyHandler()
  }

  /**
   * Gets a function that handles promise rejection, including
   * `then` handlers, `catch` handlers and `finally` handlers.
   */
  DataFlow::FunctionNode getARejectHandler() {
    result = getAHandler("then", 1) or
    result = getACatchHandler() or
    result = getAFinallyHandler()
  }

  /**
   * Gets a `catch` handler of this promise.
   */
  DataFlow::FunctionNode getACatchHandler() { result = getAHandler("catch", 0) }

  /**
   * Gets a `finally` handler of this promise.
   */
  DataFlow::FunctionNode getAFinallyHandler() { result = getAHandler("finally", 0) }
}

/** Holds if the `i`th callback handler is installed by method `m`. */
private predicate hasHandler(DataFlow::InvokeNode promise, string m, int i) {
  exists(promise.getAMethodCall(m).getCallback(i))
}

/**
 * A call that looks like a Promise.
 *
 * For example, this could be the call `promise(f).then(function(v){...})`
 */
class PromiseCandidate extends DataFlow::InvokeNode {
  PromiseCandidate() {
    hasHandler(this, "then", [0 .. 1]) or
    hasHandler(this, "catch", 0) or
    hasHandler(this, "finally", 0)
  }
}

/**
 * A promise object created by the standard ECMAScript 2015 `Promise` constructor.
 */
private class ES2015PromiseDefinition extends PromiseDefinition, DataFlow::NewNode {
  ES2015PromiseDefinition() { this = DataFlow::globalVarRef("Promise").getAnInstantiation() }

  override DataFlow::FunctionNode getExecutor() { result = getCallback(0) }
}

/**
 * A promise that is created and resolved with one or more value.
 */
abstract class PromiseCreationCall extends DataFlow::CallNode {
  /**
   * Gets the value this promise is resolved with.
   */
  abstract DataFlow::Node getValue();
}

/**
 * A promise that is created using a `.resolve()` call.
 */
abstract class ResolvedPromiseDefinition extends PromiseCreationCall { }

/**
 * A resolved promise created by the standard ECMAScript 2015 `Promise.resolve` function.
 */
class ResolvedES2015PromiseDefinition extends ResolvedPromiseDefinition {
  ResolvedES2015PromiseDefinition() {
    this = DataFlow::globalVarRef("Promise").getAMemberCall("resolve")
  }

  override DataFlow::Node getValue() { result = getArgument(0) }
}

/**
 * An aggregated promise produced either by `Promise.all` or `Promise.race`.
 */
class AggregateES2015PromiseDefinition extends PromiseCreationCall {
  AggregateES2015PromiseDefinition() {
    exists(string m | m = "all" or m = "race" |
      this = DataFlow::globalVarRef("Promise").getAMemberCall(m)
    )
  }

  override DataFlow::Node getValue() {
    result = getArgument(0).getALocalSource().(DataFlow::ArrayCreationNode).getAnElement()
  }
}

/**
 * This module defines how data-flow propagates into and out a Promise.
 */
module PromiseFlow { // TODO: Private!
  // TODO: ExceptionalReturn of all the callbacks!
  string resolveField() {
    result = "$PromiseResolveField$"
  }
  
  string rejectField() {
    result = "$PromiseRejectField$"
  }
  
  class CreationStep extends DataFlow::AdditionalFlowStep { // TODO: Promise.reject(..) ? 
    PromiseCreationCall promise;
    CreationStep() {
      this = promise
    }

    override predicate store(DataFlow::Node pred, DataFlow::Node succ, string prop) {
      prop = resolveField() and
      pred = promise.getValue() and
      succ = this
    }
  }
  
  class PromiseDefitionStep extends DataFlow::AdditionalFlowStep {
    PromiseDefinition promise;
    PromiseDefitionStep() {
      this = promise
    }

    override predicate store(DataFlow::Node pred, DataFlow::Node succ, string prop) {
      prop = resolveField() and
      pred = promise.getResolveParameter().getACall().getArgument(0) and
      succ = this
      or
      prop = rejectField() and
      pred = promise.getRejectParameter().getACall().getArgument(0) and
      succ = this
    }
  }
  
  class AwaitStep extends DataFlow::AdditionalFlowStep {
    DataFlow::Node operand;
    AwaitExpr await;
    AwaitStep() {
      this.getEnclosingExpr() = await and
      operand.getEnclosingExpr() = await.getOperand()
    }

    override predicate load(DataFlow::Node pred, DataFlow::Node succ, string prop) {
      prop = resolveField() and
      succ = this and
      pred = operand 
      or
      prop = rejectField() and
      succ = await.getExceptionTarget() and
      pred = operand
    }
  }
  
  class ThenStep extends DataFlow::AdditionalFlowStep, DataFlow::MethodCallNode {
    ThenStep() {
      this.getMethodName() = "then"
    }

    override predicate load(DataFlow::Node pred, DataFlow::Node succ, string prop) {
      prop = resolveField() and
      pred = getReceiver() and
      succ = getCallback(0).getParameter(0)
      or
      prop = rejectField() and
      pred = getReceiver() and
      succ = getCallback(1).getParameter(0)
      or
      // forward the rejected value part 1 (TODO: there got to be a better way of doing this (use a bogus node as middle-man?)).
      shouldForwardReject() and
      prop = rejectField() and
      pred = getReceiver() and
      succ = this
    }

    private predicate shouldForwardReject() {
      not exists(this.getArgument(1))
    }
    
    override predicate store(DataFlow::Node pred, DataFlow::Node succ, string prop) {
      prop = resolveField() and
      pred = getCallback([0..1]).getAReturn() and
      succ = this
      or
      // forward the rejected value part 2
      shouldForwardReject() and
      prop = rejectField() and
      pred = this and
      succ = this      
    }
  }
  
  class CatchStep extends DataFlow::AdditionalFlowStep, DataFlow::MethodCallNode {
    CatchStep() {
      this.getMethodName() = "catch"
    }

    override predicate load(DataFlow::Node pred, DataFlow::Node succ, string prop) {
      prop = rejectField() and
      pred = getReceiver() and
      succ = getCallback(0).getParameter(0)
      or
      // forwarding the resolved value part 1 (TODO: there got to be a better way of doing this (use a bogus node as middle-man?)).
      prop = resolveField() and
      pred = this and
      succ = this
    }
  
   override predicate store(DataFlow::Node pred, DataFlow::Node succ, string prop) {
      // forwarding the resolved value part 2
      prop = resolveField() and
      pred = getReceiver() and
      succ = this
    }
  }
  
  // TODO: .finally(). Including straight-transfer store.
}

/**
 * Holds if taint propagates from `pred` to `succ` through promises.
 */
predicate promiseTaintStep(DataFlow::Node pred, DataFlow::Node succ) {
  // from `x` to `new Promise((res, rej) => res(x))`
  pred = succ.(PromiseDefinition).getResolveParameter().getACall().getArgument(0)
  or
  // from `x` to `Promise.resolve(x)`
  pred = succ.(PromiseCreationCall).getValue()
  or
  exists(DataFlow::MethodCallNode thn, DataFlow::FunctionNode cb |
    thn.getMethodName() = "then" and cb = thn.getCallback(0)
  |
    // from `p` to `x` in `p.then(x => ...)`
    pred = thn.getReceiver() and
    succ = cb.getParameter(0)
    or
    // from `v` to `p.then(x => return v)`
    pred = cb.getAReturn() and
    succ = thn
  )
}

/**
 * An additional taint step that involves promises.
 */
/*private class PromiseTaintStep extends TaintTracking::AdditionalTaintStep { // TODO: Keep?
  DataFlow::Node source;

  PromiseTaintStep() { promiseTaintStep(source, this) }

  override predicate step(DataFlow::Node pred, DataFlow::Node succ) {
    pred = source and succ = this
  }
} */

/**
 * Provides classes for working with the `bluebird` library (http://bluebirdjs.com).
 */
module Bluebird {
  private DataFlow::SourceNode bluebird() {
    result = DataFlow::globalVarRef("Promise") or // same as ES2015PromiseDefinition!
    result = DataFlow::moduleImport("bluebird")
  }

  /**
   * A promise object created by the bluebird `Promise` constructor.
   */
  private class BluebirdPromiseDefinition extends PromiseDefinition, DataFlow::NewNode {
    BluebirdPromiseDefinition() { this = bluebird().getAnInstantiation() }

    override DataFlow::FunctionNode getExecutor() { result = getCallback(0) }
  }

  /**
   * A resolved promise created by the bluebird `Promise.resolve` function.
   */
  class ResolvedBluebidPromiseDefinition extends ResolvedPromiseDefinition {
    ResolvedBluebidPromiseDefinition() { this = bluebird().getAMemberCall("resolve") }

    override DataFlow::Node getValue() { result = getArgument(0) }
  }
  
  /**
   * An aggregated promise produced either by `Promise.all`, `Promise.race` or `Promise.map`. 
   */
  class AggregateBluebirdPromiseDefinition extends PromiseCreationCall {
    AggregateBluebirdPromiseDefinition() {
      exists(string m | m = "all" or m = "race" or m = "map" | 
        this = bluebird().getAMemberCall(m)
      )
    }

    override DataFlow::Node getValue() {
      result = getArgument(0).getALocalSource().(DataFlow::ArrayCreationNode).getAnElement()
    }
  }
  
}

/**
 * Provides classes for working with the `q` library (https://github.com/kriskowal/q).
 */
module Q {
  /**
   * A promise object created by the q `Promise` constructor.
   */
  private class QPromiseDefinition extends PromiseDefinition, DataFlow::CallNode {
    QPromiseDefinition() { this = DataFlow::moduleMember("q", "Promise").getACall() }

    override DataFlow::FunctionNode getExecutor() { result = getCallback(0) }
  }
}

private module ClosurePromise {
  /**
   * A promise created by a call `new goog.Promise(executor)`.
   */
  private class ClosurePromiseDefinition extends PromiseDefinition, DataFlow::NewNode {
    ClosurePromiseDefinition() { this = Closure::moduleImport("goog.Promise").getACall() }

    override DataFlow::FunctionNode getExecutor() { result = getCallback(0) }
  }

  /**
   * A promise created by a call `goog.Promise.resolve(value)`.
   */
  private class ResolvedClosurePromiseDefinition extends ResolvedPromiseDefinition {
    ResolvedClosurePromiseDefinition() {
      this = Closure::moduleImport("goog.Promise.resolve").getACall()
    }

    override DataFlow::Node getValue() { result = getArgument(0) }
  }

  /**
   * Taint steps through closure promise methods.
   */
  private class ClosurePromiseTaintStep extends TaintTracking::AdditionalTaintStep {
    DataFlow::Node pred;

    ClosurePromiseTaintStep() {
      // static methods in goog.Promise
      exists(DataFlow::CallNode call, string name |
        call = Closure::moduleImport("goog.Promise." + name).getACall() and
        this = call and
        pred = call.getAnArgument()
      |
        name = "all" or
        name = "allSettled" or
        name = "firstFulfilled" or
        name = "race"
      )
      or
      // promise created through goog.promise.withResolver()
      exists(DataFlow::CallNode resolver |
        resolver = Closure::moduleImport("goog.Promise.withResolver").getACall() and
        this = resolver.getAPropertyRead("promise") and
        pred = resolver.getAMethodCall("resolve").getArgument(0)
      )
    }

    override predicate step(DataFlow::Node src, DataFlow::Node dst) { src = pred and dst = this }
  }
}
