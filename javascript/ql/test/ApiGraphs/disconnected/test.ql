import javascript

query API::Node sourceRead(string member) {
  exists(DataFlow::CallNode source | source.getCalleeName() = "source" |
    result = source.getAPINode().getMember(member)
  )
}
