import javascript

query predicate test_ClientSocketNode(DataFlow::SourceNode sn, string res) {
  res = any(SocketIOClient::SocketObject o | o.ref() = sn).getNamespacePath()
}
