/**
 *Experimental API, subject to change.
 */

import javascript
private import semmle.javascript.dataflow.internal.StepSummary
private import semmle.javascript.dataflow.internal.FlowSteps

query predicate step(DataFlow::Node pred, DataFlow::Node succ) {
  // there is a unique write to the symbol, then all reads of the symbol reads this.
  exists(Symbol symbol, DataFlow::PropRead read | succ = read |
    read = symbol.getARead() and
    pred = unique(DataFlow::PropWrite write | write = symbol.getAWrite()).getRhs()
  )
  or
  exists(Symbol symbol, DataFlow::PropRead read, DataFlow::PropWrite write |
    read = succ and write.getRhs() = pred
  |
    read = symbol.getARead() and
    write = symbol.getAWrite() and
    getBase(write) = getBase(read)
  )
}

DataFlow::Node getBase(DataFlow::PropRef ref) {
  exists(DataFlow::SourceNode base | base = ref.getBase().getALocalSource() |
    // translate the "this"-node instance an instance method to the class itself.
    exists(StmtContainer container | base = DataFlow::thisNode(container) |
      result = DataFlow::thisNode(container) and
      not exists(DataFlow::ClassNode clz | clz.getAnInstanceMethod().getFunction() = container)
      or
      exists(DataFlow::ClassNode clz | clz.getAnInstanceMethod().getFunction() = container |
        result = DataFlow::thisNode(clz.getConstructor().getFunction())
      )
    )
    or
    // just get the normal type-tracking.
    not exists(StmtContainer container | base = DataFlow::thisNode(container)) and
    result = base
  )
  or
  exists(DataFlow::FunctionNode member, DataFlow::ClassNode clz | clz.getAnInstanceMethod() = member |
    ref.(DataFlow::PropWrite).getRhs() = member and
    result = DataFlow::thisNode(clz.getConstructor().getFunction())
  )
}

class Symbol extends DataFlow::Node {
  Symbol() { this = DataFlow::globalVarRef("Symbol").getACall() }

  DataFlow::PropRef getAPropertyReference() {
    result.getPropertyNameExpr().flow().getALocalSource() = ref()
  }

  DataFlow::PropRead getARead() { result = getAPropertyReference() }

  DataFlow::PropWrite getAWrite() { result = getAPropertyReference() }

  private DataFlow::SourceNode ref() {
    this = unique(Symbol symCall | result = symbol(DataFlow::TypeTracker::end(), symCall))
  }

  // only if known
  string getString() { result = this.(DataFlow::CallNode).getArgument(0).getStringValue() }
}

// copy paste from type-tracking, but without calls. (because non-monotonic recusion)
private DataFlow::SourceNode symbol(DataFlow::TypeTracker t, Symbol symbol) {
  t.start() and
  result = symbol
  or
  exists(
    DataFlow::TypeTracker t2, StepSummary summary, DataFlow::Node pred, DataFlow::SourceNode succ
  |
    t2 = t.append(summary) and symbol(t, symbol).flowsTo(pred) and succ = result
  |
    // Flow through properties of objects
    propertyFlowStep(pred, succ) and
    summary = LevelStep()
    or
    // Flow through an instance field between members of the same class
    DataFlow::localFieldStep(pred, succ) and
    summary = LevelStep()
    or
    exists(string prop |
      basicStoreStep(pred, succ, prop) and
      summary = StoreStep(prop)
      or
      basicLoadStep(pred, succ, prop) and
      summary = LoadStep(prop)
    )
    or
    // Store to global access path
    exists(string name |
      pred = AccessPath::getAnAssignmentTo(name) and
      AccessPath::isAssignedInUniqueFile(name) and
      succ = DataFlow::globalAccessPathRootPseudoNode() and
      summary = StoreStep(name)
    )
    or
    // Load from global access path
    exists(string name |
      succ = AccessPath::getAReferenceTo(name) and
      AccessPath::isAssignedInUniqueFile(name) and
      pred = DataFlow::globalAccessPathRootPseudoNode() and
      summary = LoadStep(name)
    )
    or
    // Store to non-global access path
    exists(string name |
      pred = AccessPath::getAnAssignmentTo(succ, name) and
      summary = StoreStep(name)
    )
    or
    // Load from non-global access path
    exists(string name |
      succ = AccessPath::getAReferenceTo(pred, name) and
      summary = LoadStep(name) and
      name != ""
    )
  )
}
