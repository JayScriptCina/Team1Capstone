import { LightningElement, api, track } from 'lwc';
  
export default class CaseActivityList extends LightningElement {
  // Data from caseTimeline LWC
  _activities = [];
  
  // Updateable data
  @track tableData = [];
  @track slicedData = [];
  @track slicedData = [];
  @track filteredDataCount;
  
  // Variables for datatable pagination
  index = 0;
  increment = 6;
  
  // Columns Definition
  columns = [
    { label: 'Type', fieldName: 'Activity_Type__c', type: 'text' },
    { label: 'Context', fieldName: 'Context__c', type: 'text' },
    { label: 'Error Message', fieldName: 'Error_Message__c', type: 'text' },
    { label: 'Stack Trace', fieldName: 'Stack_Trace__c', type: 'text' }
  ];
  
  @api
  get activities() {
    return this._activities;
  }
  set activities(value) {
    console.log("setting _activities in caseActivityList.js");
    this._activities = value || [];
    this.initializeData();
  }

  initializeData() {
    this.tableData = [...this._activities];
    this.filteredData = [...this.tableData];
    console.log('filtered data:', this.filteredData);
    
    this.filteredDataCount = this.filteredData.length;
  }

  get hasData() {
    return this.filteredData && this.filteredData.length > 0;
  }

  get cardTitle() {
    return "Case Activities for " + this.filteredData[0].caseId;
  }
  
  // Used for pagination of the lwc datatable
  get rowOffset() {
    return this.index * this.increment;
  }
  
  get prevButtonDisabled() {
    return this.index === 0; // true if we are at page 1
  }
  
  get nextButtonDisabled() {
    return this.index >= this.maxIndex; // true if we are at the final page
  }

  get maxIndex() {
    return Math.floor((this.filteredData.length) / this.increment);
  }
  
  handleRowAction(event) {
    this.dispatchEvent(new CustomEvent('handlerowaction', event));
  }
  
  updateSlicedData() {
    this.slicedData = this.filteredData.slice(this.index * this.increment, (this.index + 1) * this.increment);
  }
  
  handlePrevious() { 
    if(this.index > 0) {
      this.index--;
      this.updateSlicedData();
    }
  }
  
  handleNext() {
    if(this.index < this.maxIndex) {
      this.index++;
      this.updateSlicedData();
    }
  }

  handleRefresh() {
    this.dispatchEvent(new CustomEvent('refreshbutton'));
  }
}