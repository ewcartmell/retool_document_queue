import {Document, Shipment, Coordinator} from '../src/dsClasses.js';

import * as get_shared_cis_json from '/Users/nedcartmell/Documents/GitHub/mocha_unit_testing/src/data/get_cis_shared.json' assert { type: 'json'}
import * as get_assigned_cis_json from '/Users/nedcartmell/Documents/GitHub/mocha_unit_testing/src/data/get_assigned_cis.json' assert { type: 'json'}
import * as get_latest_uploaded_docs_json from '/Users/nedcartmell/Documents/GitHub/mocha_unit_testing/src/data/get_latest_uploaded_docs.json' assert { type: 'json'}
import * as get_official_ci_keyers_json from '/Users/nedcartmell/Documents/GitHub/mocha_unit_testing/src/data/get_official_ci_keyers.json' assert { type: 'json'}

var get_shared_cis = Object.values(get_shared_cis_json)
var get_assigned_cis = Object.values(get_assigned_cis_json)
var get_latest_uploaded_docs = Object.values(get_latest_uploaded_docs_json)
var get_official_ci_keyers = Object.values(get_official_ci_keyers_json)

/* console.log(get_shared_cis.slice(0,10))
console.log(get_assigned_cis.slice(0,10))
console.log(get_latest_uploaded_docs.slice(0,10))
console.log(get_official_ci_keyers.slice(0,10)) */


//var doc = new Document(get_shared_cis[0][0])

get_shared_cis[0].forEach(function (item, index) {
  var doc = Document.get_document(item.DOCUMENT_ID)
  if(doc == null) {
    new Document(item)
  } else {
    Object.assign(doc, item)
  }
});

get_assigned_cis[0].forEach(function (item, index) {
  var doc = Document.get_document(item.GSHEET_DOCUMENT_ID)
  if(doc == null) {
    new Document(item)
  } else {
    Object.assign(doc, item)
  }
});

/*
get_latest_uploaded_docs[0].forEach(function (item, index) {
  var doc = Document.get_document(item.GRAPHQL_DOCUMENT_ID)
  if(doc == null) {
    new Document(item)
  } else {
    Object.assign(doc, item)
  }
});*/

function build_or_assign(arr = []) {
    arr.forEach(function (item, index) {
    var doc = Document.get_document(item.GRAPHQL_DOCUMENT_ID)
    if(doc == null) {
      new Document(item)
    } else {
      Object.assign(doc, item)
    }
  })
}

build_or_assign(get_latest_uploaded_docs[0])

//console.log(Document.all.filter(d => !(d.GRAPHQL_DOCUMENT_ID == null)).length)
console.log(Document.all.filter(d => !(d.GRAPHQL_DOCUMENT_ID ==null)))
