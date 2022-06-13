
class Coordinator {
  static all = []

  static get_selected_site_coordinators(sites = []){
    return Coordinator.all.filter(coordinator => sites.includes(coordinator.SITE))
  }


  static get_coordinators_assigned_documents(COMPANY) {

    var coordinators = Coordinator.all.filter(c =>
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
      var assigned_cis = item.get_assigned_documents()
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
    var documents = Document.all;
    return documents.filter(document => document.GSHEET_ASSIGNED_TO_EMAIL === this.EMAIL);
  }


}


module.exports = Coordinator