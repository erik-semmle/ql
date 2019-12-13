import javascript

query predicate test_ClientSendNode(
  SocketIOClient::SendNode sn, DataFlow::SourceNode res0, string res1
) {
  res0 = sn.getSocket().ref() and res1 = sn.getNamespacePath()
}
