import javascript

query predicate test_StandardRouteHandler(
  Express::StandardRouteHandler rh, DataFlow::Node res0, SimpleParameter res1, SimpleParameter res2
) {
  res0 = rh.getServer() and res1 = rh.getRequestParameter() and res2 = rh.getResponseParameter()
}
