import javascript

query predicate test_ClientReceiveNode(
  SocketIOClient::ReceiveNode rn, DataFlow::SourceNode res
) {
  res = rn.getSocket().ref()
}
