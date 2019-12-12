import javascript

query predicate test_SocketNode(SocketIO::SocketNode sn, SocketIO::ServerNamespace res) {
  res = sn.getNamespace()
}
