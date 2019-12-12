import javascript

query predicate test_ServerNode(DataFlow::SourceNode srv, SocketIO::ServerObject res) {
  res.ref() = srv
}
