import { LightningElement, api, track } from 'lwc';
  
export default class CaseActivityList extends LightningElement {
  // Data from caseTimeline LWC
  _activities = [];
  @api activityTypeOptions = [];
  
  // Updateable data
  @track tableData = [];
  @track filteredData = [];
  @track slicedData = [];
  @track filters = { caseNumber: '', createdDate: '', activityType: '', context: '', errorMessage: '', stackTrace: '' };
  @track filteredDataCount;
  
  // Variables for datatable pagination
  index = 0;
  increment = 6;
  
  // Columns Definition
  columns = [
    { label: 'Case#', fieldName: 'CaseNumber', type: 'text'},
    { label: 'Date', fieldName: 'CreatedDateFormatted', type: 'text', wrapText: true },
    { label: 'Type', fieldName: 'Activity_Type__c', type: 'text' },
    { label: 'Context', fieldName: 'Context__c', type: 'text' },
    { label: 'Error Message', fieldName: 'Error_Message__c', type: 'text' },
    { label: 'Stack Trace', fieldName: 'Stack_Trace__c', type: 'text' },
    {
      type: 'button',
      typeAttributes: {
        label: 'More Details →',
        name: 'view_details',
        variant: 'base'
      }
    }
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
    
    this.applyFilters();

    this.filteredDataCount = this.filteredData.length;
  }

  get hasData() {
    return this.filteredData && this.filteredData.length > 0;
  }
  
  // Used for pagination of the lwc datatable
  get rowOffset() {
    return this.index * this.increment;
  }
  
  get prevButtonDisabled() {
    return this.index === 0; // true if we are at page 1
  }

  get activityTypeOptionsArr() {
    return this.activityTypeOptions;
  }
  
  get resetButtonDisabled() {
    if(Object.values(this.filters).every(value => value === '')) {
      return true;
    }
    else {
      return false;
    }
  }

  get nextButtonDisabled() {
    return this.index >= this.maxIndex; // true if we are at the final page
  }

  get maxIndex() {
    return Math.floor((this.filteredData.length) / this.increment);
  }
  
  // Handle Filter Change
  handleFilterChange(event) {
    const filterType = event.target.dataset.filter;
    const filterValue = event.target.value;
    console.log('value selected was', event.target.value);
    
    this.filters = { ...this.filters, [filterType]: filterValue };
    this.applyFilters();
  }

  handleRowAction(event) {
    this.dispatchEvent(new CustomEvent('handlerowaction', event));
  }
  
  updateSlicedData() {
    this.slicedData = this.filteredData.slice(this.index * this.increment, (this.index + 1) * this.increment);
  }

  // Apply Filters to Data
  applyFilters() {
    this.index = 0;
    
    try {
      this.filteredData = this.tableData.filter(item => {
        // console.log('item is:', item);
        const caseNumber = (item.CaseNumber || '');
        const createdDate = (item.CreatedDateFormatted || '');
        const activityType = (item.Activity_Type__c || '');
        const context = (item.Context__c || '');
        const errorMessage = (item.Error_Message__c || '');
        const stackTrace = (item.Stack_Trace__c || '');
        // console.log( 'caseNumber:', caseNumber, 'createdDate', createdDate, 'activityType', activityType, '... more');
        return (
          (this.filters.caseNumber ? caseNumber.includes(this.filters.caseNumber) : true) &&
          (this.filters.createdDate ? createdDate.toLowerCase().includes(this.filters.createdDate.toLowerCase()) : true) &&
          (this.filters.activityType ? activityType === this.filters.activityType : true) &&
          (this.filters.context ? context.toLowerCase().includes(this.filters.context.toLowerCase()) : true) &&
          (this.filters.errorMessage ? errorMessage.toLowerCase().includes(this.filters.errorMessage.toLowerCase()) : true) &&
          (this.filters.stackTrace ? stackTrace.toLowerCase().includes(this.filters.stackTrace.toLowerCase()) : true)
        );
      });
      
      this.updateSlicedData();
    }
    catch (error) {
      console.error('error applyFilters()', error);
    }
  }
  
  // Reset Filters
  resetFilters() {
    this.filters = { caseNumber: '', createdDate: '', activityType: '', context: '', errorMessage: '', stackTrace: '' };
    this.filteredData = [...this.tableData];
    this.updateSlicedData();
    this.index = 0;
    
    // Reset UI Inputs
    this.template.querySelectorAll('lightning-input, lightning-combobox').forEach(input => {
      input.value = '';
    });
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