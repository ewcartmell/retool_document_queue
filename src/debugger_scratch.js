
/*
function get_documents_status(date_part, cart_documents, assigned_documents, docs) {
    var results = [];

    docs.reduce(function(res, value) {
      //var status = value.get_document_status(cart_documents, assigned_documents)
      var status = 'Up for Grabs'
      if(!(value.GRAPHQL_KEYED_AT == null)) {
        status = 'Keyed'
      } else if (cart.includes(value.DOCUMENT_ID)) {
        status = 'In Cart'
      } else if (assigned.includes(value.DOCUMENT_ID)) {
        status = 'Assigned'
      }

      //var date_adjusted = value.get_arrival_date_part(date_part)

      if(value.ARRIVAL_DATE instanceof Date) {
        var year = value.ARRIVAL_DATE.getYear()
        var month = value.ARRIVAL_DATE.getMonth()
        var week_day = value.ARRIVAL_DATE.getDate() - value.ARRIVAL_DATE.getDay()
        var day = value.ARRIVAL_DATE.getDate()
        var date_adjusted = ""

        switch(date_part) {
          case 'year':
            date_adjusted = new Date(year, 1, 1);
            break;
          case 'month':
            date_adjusted = new Date(year, month, 1);
            break;
          case 'week':
            date_adjusted = new Date(year, month, week_day);
            default:
            break;
            date_adjusted = new Date(year, month, day);
        }

      var key = date_adjusted + '-' + value.STATUS;

      if (!res[key]) {
        res[key] = {
          STATUS: status,
          ARRIVAL_DATE: date_adjusted.toISOString().split('T')[0],
          CIS: 0
        };
        results.push(res[key])
      }
      res[key].CIS += 1;
      return res;
    }, {});
    return results;
  )
}

var docs = get_documents_status(date_part = date_part, cart_documents = cart_documents, assigned_documents = assigned_documents, docs = docs)

return docs
//return Document.all
//return Document.all[0].ARRIVAL_DATE.getYear()