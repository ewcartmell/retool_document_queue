window.Document = class Document {
  static all = []

  static get_document(DOCUMENT_ID) {
    return Document.all.filter(row => row.DOCUMENT_ID == DOCUMENT_ID)[0]
  }

  static check_document(DOCUMENT_ID) {
    return Document.all.map(row => row.DOCUMENT_ID).includes(DOCUMENT_ID)
  }

  static toggle_transcribed(transcribed = null, arr = Document.all) {
  	if(!(transcribed == null)) {
      arr = arr.filter(row => !(row.GRAPHQL_KEYED_AT == null) == transcribed);
    }
    return arr
  }

  static toggle_team(bpo = null, arr = Document.all) {
    if(!(bpo == null)) {
      arr = arr.filter(row => (row.SN == 'Support Ninja') == bpo);
    }
    return arr
  }

  static toggle_assigned(assigned = null, arr = Document.all) {
    if(!(assigned == null)) {
      arr = arr.filter(row => !(row.GSHEET_DOCUMENT_ID == null) == assigned);
    }
    return arr
  }

  static toggle_cart(cart = null, cart_documents = [], arr = Document.all) {
    if(!(cart == null))  {
        arr = arr.filter(row => (cart_documents.includes(row.DOCUMENT_ID)) == cart);
    }
    return arr;
  }

  static toggle_pending(pending = null, arr = Document.all) {
    if(!(pending == null))  {
        arr = arr.filter(row => !(row.PENDING_NOTE == null) == pending);
    }
    return arr;
  }


  static get_client_cis(clients = [], arr = Document.all) {
    if(clients.length > 0) {
      arr = arr.filter(row => clients.includes(row.CLIENT));
    }
    return arr;
  }

  static get_filtered_cis(clients = [], cart = null, cart_documents = [], team = [], assigned = null, transcribed = null, pending = null) {
    var bpo = (team.includes('Support Ninja') || team.includes('Lean Staffing Group'))
    var arr = Document.all

    arr = Document.get_client_cis(clients, arr);
    arr = Document.toggle_cart(cart, cart_documents, arr);
    arr = Document.toggle_team(bpo, arr);
    arr = Document.toggle_assigned(assigned, arr);
    arr = Document.toggle_transcribed(transcribed, arr);
    arr = Document.toggle_pending(pending, arr);

    return arr
  }

  static get_documents_status(date_part, cart_documents, assigned_documents) {
    var docs = Document.all;
    var results = [];

    docs.reduce(function(res, value) {
      var status = value.get_document_status(cart_documents, assigned_documents)
      var date_adjusted = value.get_arrival_date_part(date_part)
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
  }

  constructor(document) {
    //From Snowflake
    this.DOCUMENT_ID = document.DOCUMENT_ID;
    this.SHIPMENT_ID = document.SHIPMENT_ID;
    this.SHIPMENT_LINK = document.SHIPMENT_LINK;
    this.CUSTOMS = document.CUSTOMS;
    this.INSURANCE = document.INSURANCE;
    this.MODE = document.MODE;
    this.PDR = document.PDR;
    this.RF = document.RF;
    this.SN = document.SN;
    this.TIME = document.TIME;
    this.TIER = document.TIER;
    this.SOP = document.SOP;
    this.PENDING_NOTE = document.PENDING_NOTE;
    this.PENDING_PERSON = document.PENDING_PERSON;
    this.PENDING_CREATED_TS = document.PENDING_CREATED_TS;
    this.REPLY_NOTE = document.REPLY_NOTE;
    this.REPLY_PERSON = document.REPLY_PERSON;
    this.REPLY_CREATED_TS = document.REPLY_CREATED_TS;
    this.DOCUMENT_URL = document.DOCUMENT_URL;
    this.FIRST_UPLOADED_ON = document.FIRST_UPLOADED_ON;
    this.FIRST_UPLOADED_BY = document.FIRST_UPLOADED_BY;
    this.FIRST_UPLOADED_BY_EMAIL = document.FIRST_UPLOADED_BY_EMAIL;
    this.FILE_NAME = document.FILE_NAME;
    this.CLIENT = document.COMPANY_NAME;
    this.ARRIVAL_DATE = new Date(document.ARRIVAL_DATE);
    this.DUE_DATE = new Date(document.DUE_DATE);
    this.ACTION_TYPE = document.ACTION_TYPE;
    //this.PRODUCTS_FIRST_ENTERED_AT = document.PRODUCTS_FIRST_ENTERED_AT;

    //From Google Sheet
    this.GSHEET_DOCUMENT_ID = document.GSHEET_DOCUMENT_ID
    this.GSHEET_ASSIGNED_TS = document.GSHEET_ASSIGNED_TS;
    this.GSHEET_ASSIGNED_TO_ID = document.GSHEET_ASSIGNED_TO_ID;
    this.GSHEET_ASSIGNED_TO_FULL_NAME = document.GSHEET_ASSIGNED_TO_FULL_NAME;
    this.GSHEET_ASSIGNED_TO_EMAIL = document.GSHEET_ASSIGNED_TO_EMAIL;

    //From GraphQL
    this.GRAPHQL_DOCUMENT_CREATED_AT = document.GRAPHQL_DOCUMENT_CREATED_AT;
    this.GRAPHQL_DOCUMENT_ID = document.GRAPHQL_DOCUMENT_ID;
    this.GRAPHQL_DOCUMENT_ARCHIVED_AT = document.GRAPHQL_ARCHIVED_AT;
    if(document.hasOwnProperty('GRAPHQL_KEYED_AT.productsFirstEnteredAt')) {
      this.GRAPHQL_KEYED_AT = document.GRAPHQL_KEYED_AT.productsFirstEnteredAt
    };

    //Create Shipment
		var existing_shipments = Document.all.map(document => document.SHIPMENT_ID)
    if(!(existing_shipments.includes(document.SHIPMENT_ID))) {
    	new Shipment(document)
    } else {
      Shipment.get_shipment(document.SHIPMENT_ID).increment_cis()
    }

    Document.all.push(this)
  }

  get_shipment() {
     return Shipment.all.filter(shipment => shipment.SHIPMENT_ID === this.SHIPMENT_ID)[0];
  }
  get_document_status(cart, assigned) {
    var status = 'Up for Grabs'
    if(!(this.GRAPHQL_KEYED_AT == null)) {
      status = 'Keyed'
    } else if (cart.includes(this.DOCUMENT_ID)) {
      status = 'In Cart'
    } else if (assigned.includes(this.DOCUMENT_ID)) {
      status = 'Assigned'
    }
    return status
  }

  assign_document(ASSIGNMENT_INFO) {
    Object.assign(this, ASSIGNMENT_INFO);
  }

  get_arrival_date_part(date_part) {

    var year = this.ARRIVAL_DATE.getYear()
    var month = this.ARRIVAL_DATE.getMonth()
    var week_day = this.ARRIVAL_DATE.getDate() - this.ARRIVAL_DATE.getDay()
    var day = this.ARRIVAL_DATE.getDate()

    switch(date_part) {
      case 'year':
        return new Date(year, 1, 1);
        break;
      case 'month':
        return new Date(year, month, 1);
        break;
      case 'week':
        return new Date(year, month, week_day);
        break;
      default:
        return new Date(year, month, day);

    }
  }

}

//module.exports = window.Document
