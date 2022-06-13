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
  this.SHIPMENT_ID = shipment.SHIPMENT_ID;

  constructor(shipment) {
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
