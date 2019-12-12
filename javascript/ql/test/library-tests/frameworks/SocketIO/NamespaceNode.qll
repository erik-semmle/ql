import javascript

query predicate test_NamespaceNode(SocketIO::NamespaceNode ns, SocketIO::ServerNamespace res) {
  res = ns.getNamespace()
}
