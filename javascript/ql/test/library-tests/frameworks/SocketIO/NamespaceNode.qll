import javascript

query predicate test_NamespaceNode(DataFlow::SourceNode ns, SocketIO::NamespaceObject res) {
  res = any(SocketIO::NamespaceBase o | o.ref() = ns).getNamespace()
}
