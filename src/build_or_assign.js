window.build_or_assign = function build_or_assign(arr = []) {
  arr.forEach(function (item, index) {
  var doc = Document.get_document(item.GRAPHQL_DOCUMENT_ID)
  if(doc == null) {
    new Document(item)
  } else {
    Object.assign(doc, item)
  }
})
}
