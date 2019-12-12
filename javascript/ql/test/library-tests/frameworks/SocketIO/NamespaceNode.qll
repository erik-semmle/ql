import javascript

query predicate test_NamespaceNode(DataFlow::SourceNode ns, SocketIO::ServerNamespace res) {
  res = any(SocketIO::NamespaceObject o | o.ref() = ns).getNamespace()
}
