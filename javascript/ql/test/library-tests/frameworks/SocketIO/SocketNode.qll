import javascript

query predicate test_SocketNode(DataFlow::SourceNode sn, SocketIO::ServerNamespace res) {
  res = any(SocketIO::SocketObject o | o.ref() = sn).getNamespace()
}
