
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

  static toggle_team(team = [], arr = Document.all) {
    if(team.length > null) {
      team = (team.includes('Support Ninja') || team.includes('Lean Staffing Group'))
      arr = arr.filter(row => (row.SN == 'Support Ninja') == team);
    }
    return arr
  }

  static toggle_bpo(bpo = null, arr = Document.all) {
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

  static get_filtered_cis(clients = [], cart = null, cart_documents = [], team = [], bpo = null, assigned = null, transcribed = null, pending = null, arr = Document.all) {

    arr = Document.get_client_cis(clients, arr);
    arr = Document.toggle_cart(cart, cart_documents, arr);
    arr = Document.toggle_team(team, arr);
    arr = Document.toggle_bpo(bpo, arr);
    arr = Document.toggle_assigned(assigned, arr);
    arr = Document.toggle_transcribed(transcribed, arr);
    arr = Document.toggle_pending(pending, arr);

    return arr
  }

  static get_documents_status(date_part, cart_documents, assigned_documents, arr = Document.all) {
    var results = [];

    arr.reduce(function(res, value) {
      var status = value.get_document_status(cart_documents, assigned_documents)
      var date_adjusted = value.get_arrival_date_part(date_part)
      var key = date_adjusted.toString() + '-' + status;
      if (!res[key]) {
        res[key] = {
          STATUS: status,
          ARRIVAL_DATE: (date_adjusted == 'Invalid Date' || date_adjusted == null) ? null : date_adjusted.toISOString().split('T')[0],
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

    if(this.ARRIVAL_DATE instanceof Date) {
      var year = this.ARRIVAL_DATE.getYear() + 1900
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

}




window.Shipment = class Shipment {
  static all = []
  static shipment_ids = Shipment.all.map(shipment => shipment.SHIPMENT_ID)
  static get_shipment(SHIPMENT_ID) {
    return Shipment.all.filter(row => row.SHIPMENT_ID == SHIPMENT_ID)[0]
  }
  static check_shipment(SHIPMENT_ID) {
    return Shipment.all.map(row => row.SHIPMENT_ID).includes(SHIPMENT_ID)
  }

  static sort_shipments(filtered_cis = []) {
    var output = [];
    if(filtered_cis.length > 0) {
      var filtered_shipment_ids = filtered_cis.map(row => row.SHIPMENT_ID)
      output = Shipment.all.filter(row => filtered_shipment_ids.includes(row.SHIPMENT_ID));
    } else {
      output = Shipment.all
    }
    output.sort(function(a,b){
      // Turn your strings into dates, and then subtract them
      // to get a value that is either negative, positive, or zero.
    	return new Date(a.ARRIVAL_DATE) - new Date(b.ARRIVAL_DATE);
    });
    return output
	}

  constructor(shipment) {
    this.SHIPMENT_ID = shipment.SHIPMENT_ID;
    this.SHIPMENT_LINK = shipment.SHIPMENT_LINK;
    this.CLIENT = shipment.COMPANY_NAME;
    this.ARRIVAL_DATE = shipment.ARRIVAL_DATE;
    this.DUE_DATE = shipment.DUE_DATE;
    this.BPO = shipment.SN;
    this.PENDING = shipment.PENDING_NOTE;
    this.TOTAL_CIS = 1;
    Shipment.all.push(this)
  }

  get_documents() {
     return Document.all.filter(document => document.SHIPMENT_ID === this.SHIPMENT_ID);
  }

  increment_cis() {
    this.TOTAL_CIS += 1;
  }
}




window.Coordinator = class Coordinator {
  static all = []

  static get_selected_site_coordinators(sites = []){
    return Coordinator.all.filter(coordinator => sites.includes(coordinator.SITE))
  }


  static get_coordinators_assigned_documents(COMPANY, docs = Document.all, arr = Coordinator.all) {

    var coordinators = arr.filter(c =>
      c.TEAM == 'Product Data'
      && COMPANY.includes(c.COMPANY)
      && c.ROLE === 'Execution'
    )

    var results = coordinators.map(c => ({
        COORDINATOR: c.NAME,
        TEAM: c.TEAM,
        COMPANY: c.COMPANY,
        DAYS_OLD: 0,
        CIS: 0
      })
    )

    coordinators.forEach(function (item, index) {
      var assigned_cis = docs.filter(document => document.GSHEET_ASSIGNED_TO_EMAIL === item.EMAIL);

      assigned_cis.reduce(function(res, value) {
      var days_old = moment(value.GSHEET_ASSIGNED_TS).diff(moment(), 'days')*-1
        if (!res[days_old]) {
          res[days_old] = {
            COORDINATOR: item.NAME,
            TEAM: item.TEAM,
            COMPANY: item.COMPANY,
            DAYS_OLD: days_old,
            CIS: 0
          };
          results.push(res[days_old])
        }
        res[days_old].CIS += 1;
        return res;
      }, {});
    })

  	return results
  }

  constructor(coordinator) {
    this.NAME = coordinator.Worker;
    this.EMAIL = coordinator.Email;
    this.CORE_USER_ID = coordinator.USER_ID;
    this.SITE = coordinator.Location;
    this.TIER = coordinator.TIER;
    this.POSITION = coordinator.Position;
    this.SUPERVISORY_ORG = coordinator['Supervisory Organization'];
    this.BPO_MANAGER = coordinator.SN_MANAGER;
    this.LOB = coordinator.LOB;
    this.TEAM = coordinator.TEAM;
    this.WORKFLOS = coordinator.WORKFLOW;
    this.SPECIALIZATION = coordinator.SPECIALIZATION;
    this.PM = coordinator['DS Owner (PM or TM)'];
    this.USER_ID = coordinator.USER_ID;
    this.TEAM = coordinator['Confirmed Team'];
    this.WORKFLOW = coordinator['Confirmed Workflow'];
    this.ROLE = coordinator['Confirmed Role'];
    this.MANAGER = coordinator['Confirmed Manager'];
    this.COMPANY = coordinator['Confirmed Company'];
    Coordinator.all.push(this);
  }

  get_assigned_documents() {
    var docs = Document.all;
    return docs.filter(document => document.GSHEET_ASSIGNED_TO_EMAIL === this.EMAIL);
  }


}


window.build_or_assign = function build_or_assign(arr = []) {
  arr.forEach(function (item, index) {
    var doc_id = parseInt(item.DOCUMENT_ID ?? item.GSHEET_DOCUMENT_ID) ?? item.GRAPHQL_DOCUMENT_ID;
    var doc = Document.get_document(doc_id)

    if(doc == null) {
      new Document(item)
    } else {
      Object.assign(doc, item)
    }
  })
}
