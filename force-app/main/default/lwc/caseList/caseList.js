// Name: Jay Cina
// Date: 02/04/2026
// Desc: A dynamic list that displays Case data which can be filtered via typing in values (ex. name) or picking values (ex. picklist)
// Dynamic Data Table base code credit: https://medium.com/@gadige.sfdc/lwc-data-table-with-dynamic-filters-28387a11cab4
import { LightningElement, wire, track } from 'lwc';

import CASE_OBJECT from '@salesforce/schema/Case';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import PRIORITY_FIELD from '@salesforce/schema/Case.Priority';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import getCases from '@salesforce/apex/Case_Manager.getCases';

export default class DynamicDataTable extends LightningElement {
  // Sample Data
  @track tableData = [];
  @track filteredData = [];
  @track slicedData = [];
  @track filters = { status: '', priority: '', recordType: '', contact: '' };
  @track index = 0; // used for limiting the number of records shown in the list
  @track increment = 10;
  @track filteredDataCount;
  
  // Columns Definition
  columns = [
    { label: 'Case Number', fieldName: 'caseUrl', type: 'url',
      typeAttributes: {
        label: { fieldName: 'CaseNumber' },
        target: '_blank'
      }
    },
    { label: 'Status', fieldName: 'Status', type: 'text', editable: true },
    { label: 'Priority', fieldName: 'Priority', type: 'text' },
    { label: 'Record Type', fieldName: 'RecordTypeName', type: 'text' },
    { label: 'Contact', fieldName: 'contactUrl', type: 'url',
      typeAttributes: {
        label: { fieldName: 'ContactName' },
        target: '_blank'
      }
    },
    { label: 'SLA Target', fieldName: 'SLA_Target__c', type: 'date' }
  ];
  
  @wire(getCases)
  wiredCases({ data, error }) {
    if(data) { // creates a clickable link for Contacts
      this.tableData = data.map(item => ({
        ...item,
        contactUrl: item.ContactId ? '/' + item.ContactId : null,
        caseUrl: '/' + item.Id
      }));
      console.log('data received from wire:', data)
      this.filteredData = [...this.tableData];
      console.log('filtered data:', this.filteredData);

      // Set to priority filter to high upon page load
      this.filters.priority = "High";
      this.applyFilters();

      this.filteredDataCount = this.filteredData.length;
    }
    else if(error) {
      console.error("Wire error:", error);
    }
  };
  
  
  // 1. Declare object variables
  caseObjectInfo
  caseRecordTypeId;
  priorityOptions;
  statusOptions;
  recordTypeOptions;
  
  // 2. Get the default Record Type ID for Case
  @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
  objectInfo({ data, error }) {
    if (data) {
      this.caseObjectInfo = data;
      this.caseRecordTypeId = data.defaultRecordTypeId;
      this.processRecordTypes();
    }
    else if (error) {
      console.error('Error fetching case object info', error);
    }
  }
  
  // 3. Get the picklist values using the Record Type ID and Field Reference
  @wire(getPicklistValues, { 
    recordTypeId: '$caseRecordTypeId', 
    fieldApiName: PRIORITY_FIELD 
  })
  priorityPicklistValues({ data, error }) {
    if (data) {
      this.priorityOptions = data.values;
      console.log('Priority Values:', this.priorityOptions);
    } else if (error) {
      console.error('Error fetching priority picklist values', error);
    }
  }
  
  @wire(getPicklistValues, { 
    recordTypeId: '$caseRecordTypeId', 
    fieldApiName: STATUS_FIELD 
  })
  statusPicklistValues({ data, error }) {
    if (data) {
      this.statusOptions = data.values;
      console.log('Priority Values:', this.statusOptions);
    } else if (error) {
      console.error('Error fetching status picklist values', error);
    }
  }
  
  processRecordTypes() {
    const rtis = this.caseObjectInfo.recordTypeInfos;
    // The recordTypeInfos is a map, so iterate over the keys (record type IDs)
    this.recordTypeOptions = Object.keys(rtis).map(typeId => ({
      label: rtis[typeId].name,
      value: rtis[typeId].name,
      id: typeId // metadata
    }));
    console.log('our record type options are', this.recordTypeOptions);
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
    return this.index === 0;
  }

  get nextButtonDisabled() {
    const maxIndex = Math.floor((this.filteredData.length - 1) / this.increment);
    return this.index >= maxIndex;
  }
  
  // Handle Filter Change
  handleFilterChange(event) {
    const filterType = event.target.dataset.filter;
    const filterValue = event.target.value;
    console.log('value selected was', event.target.value);
    
    this.filters = { ...this.filters, [filterType]: filterValue };
    this.applyFilters();
  }
  
  updateSlicedData() {
    this.slicedData = this.filteredData.slice(this.index * this.increment, (this.index + 1) * this.increment);
  }
  // Apply Filters to Data
  applyFilters() {
    this.index = 0;
    
    try {
      this.filteredData = this.tableData.filter(item => {
        console.log('item is:', item);
        const status = (item.Status || '');
        const priority = (item.Priority || '');
        const recordType = (item.RecordTypeName || '');
        const contact = (item.ContactName || '');
        console.log( 'status:', status, 'priority', priority, 'recordType', recordType, 'contact', contact);
        return (
          (this.filters.status ? status === this.filters.status : true) &&
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
    const maxIndex = Math.floor((this.filteredData.length - 1) / this.increment);
    if(this.index < maxIndex) {
      this.index++;
      this.updateSlicedData();
    }
  }
}