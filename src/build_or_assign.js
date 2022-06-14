window.build_or_assign = function build_or_assign(arr = []) {
  arr.forEach(function (item, index) {
  var doc_id = (item.DOCUMENT_ID ?? item.GSHEET_DOCUMENT_ID) ?? item.GRAPHQL_DOCUMENT_ID;
  var doc = Document.get_document(doc_id)
  if(doc == null) {
    new Document(item)
  } else {
    Object.assign(doc, item)
  }
})
}
