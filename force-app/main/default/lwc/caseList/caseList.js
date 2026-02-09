// Name: Jay Cina
// Date: 02/04/2026
// Desc: A dynamic list that displays Case data which can be filtered via typing in values (ex. name) or picking values (ex. picklist)
// Dynamic Data Table base code credit: https://medium.com/@gadige.sfdc/lwc-data-table-with-dynamic-filters-28387a11cab4
import { LightningElement, api, track } from 'lwc';

export default class DynamicDataTable extends LightningElement {
  // Data from caseConsole LWC
  _cases = [];
  @api priorityOptions = [];
  @api statusOptions = [];
  @api recordTypeOptions = [];
  
  // Updateable data
  @track tableData = [];
  @track filteredData = [];
  @track slicedData = [];
  @track filters = { status: '', priority: '', recordType: '', contact: '' };
  @track filteredDataCount;
  
  // Variables for datatable pagination
  index = 0;
  increment = 6;
  
  // Columns Definition
  columns = [
    { label: 'Case Number', fieldName: 'caseUrl', type: 'url',
      typeAttributes: {
        label: { fieldName: 'CaseNumber' },
        target: '_blank'
      }
    },
    { label: 'Status', fieldName: 'Status', type: 'text' },
    { label: 'Priority', fieldName: 'Priority', type: 'text' },
    { label: 'Record Type', fieldName: 'RecordTypeName', type: 'text' },
    { label: 'Contact', fieldName: 'contactUrl', type: 'url',
      typeAttributes: {
        label: { fieldName: 'ContactName' },
        target: '_blank'
      }
    },
    { label: 'SLA Target', fieldName: 'SLATarget', type: 'date' },
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
  get cases() {
    return this._cases;
  }
  set cases(value) {
    console.log("setting _cases in caseList.js");
    this._cases = value || [];
    this.initializeData();
  }

  initializeData() {
    this.tableData = [...this._cases];
    this.filteredData = [...this.tableData];
    console.log('filtered data:', this.filteredData);
    
    // Set the priority filter to high upon page load
    this.filters.priority = "High";
    this.filters.status = "Not Closed";
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
  
  // Get unique Status Options
  get statusOptionsArr() {
    return this.statusOptions;
  }
  
  // Get unique Role Options
  get priorityOptionsArr() {
    return this.priorityOptions;
  }
  
  // Get unique Record Type Options
  get recordTypeOptionsArr() {
    return this.recordTypeOptions;
  }
  
  get resetButtonDisabled() {
    if(Object.values(this.filters).every(value => value === '')) {
      return true;
    }
    else {
      return false;
    }
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
        const status = (item.Status || '');
        const priority = (item.Priority || '');
        const recordType = (item.RecordTypeName || '');
        const contact = (item.ContactName || '');
        // console.log( 'status:', status, 'priority', priority, 'recordType', recordType, 'contact', contact);
        return (
          (
            !this.filters.status
            ? true : this.filters.status === 'Not Closed'
            ? status !== 'Closed' : status === this.filters.status
          ) &&
          (this.filters.priority ? priority === this.filters.priority : true) &&
          (this.filters.recordType ? recordType === this.filters.recordType : true) &&
          (this.filters.contact ? contact.includes(this.filters.contact) : true)
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
    this.filters = { status: '', priority: '', recordType: '', contact: '' };
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