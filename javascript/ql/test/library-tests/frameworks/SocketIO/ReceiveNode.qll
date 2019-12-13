import javascript

query predicate test_ReceiveNode(SocketIO::ReceiveNode rn, DataFlow::SourceNode res) {
  res = rn.getSocket()
}
