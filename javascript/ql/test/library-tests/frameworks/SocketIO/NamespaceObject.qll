import javascript

query predicate test_NamespaceObject(
  SocketIO::ServerNamespace ns, SocketIO::ServerObject res0, string res1
) {
  res0 = ns.getServer() and res1 = ns.getPath()
}
