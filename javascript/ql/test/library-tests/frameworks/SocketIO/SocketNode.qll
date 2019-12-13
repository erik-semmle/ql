import javascript

query predicate test_SocketNode(DataFlow::SourceNode sn, SocketIO::NamespaceObject res) {
  res = any(SocketIO::SocketObject o | o.ref() = sn).getNamespace()
}
