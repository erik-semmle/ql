import javascript

query predicate test_SendNode_getSocket(SocketIO::SendNode sn, DataFlow::SourceNode res) {
  res = sn.getSocket()
}
