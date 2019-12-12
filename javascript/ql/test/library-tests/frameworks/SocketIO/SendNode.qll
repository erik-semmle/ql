import javascript

query predicate test_SendNode(SocketIO::SendNode sn, SocketIO::ServerNamespace res) {
  res = sn.getNamespace()
}
