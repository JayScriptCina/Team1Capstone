// Name: Jay Cina
// Date: 02/04/2026
// Desc: A dynamic list that displays Case data which can be filtered via typing in values (ex. name) or picking values (ex. picklist)
// Dynamic Data Table base code credit: https://medium.com/@gadige.sfdc/lwc-data-table-with-dynamic-filters-28387a11cab4
import { LightningElement, wire, track } from 'lwc';

import CASE_OBJECT from '@salesforce/schema/Case';
import CASE_NUMBER_FIELD from '@salesforce/schema/Case.CaseNumber';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import PRIORITY_FIELD from '@salesforce/schema/Case.Priority';
import CONTACT_NAME_FIELD from '@salesforce/schema/Case.Contact.Name';
import SLA_TARGET_FIELD from '@salesforce/schema/Case.SLA_Target__c';
import RECORD_TYPE_NAME_FIELD from '@salesforce/schema/Case.RecordType.Name';

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
    { label: 'Case Number', fieldName: 'CaseNumber', type: 'text'},
    { label: 'Status', fieldName: 'Status', type: 'text', editable: true },
    { label: 'Priority', fieldName: 'Priority', type: 'text' },
    { label: 'Record Type', fieldName: 'RecordTypeName', type: 'text' },
    { label: 'Contact', fieldName: 'ContactId', type: 'text' },
    { label: 'SLA Target', fieldName: 'SLA_Target__c', type: 'date' }
  ];
  
  @wire(getCases)
  wiredCases({ data, error }) {
    if(data) {
      this.tableData = data;
      console.log('data received from wire:', data)
      this.filteredData = [...this.tableData];
      console.log('filtered data:', this.filteredData);
      this.updateSlicedData();
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
      value: rtis[typeId].name.toLowerCase(),
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
  
  // Handle Filter Change
  handleFilterChange(event) {
    const filterType = event.target.dataset.filter;
    const filterValue = event.target.value.toLowerCase();
    console.log('value selected was', event.target.value.toLowerCase());
    
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
        const status = (item.Status || '').toLowerCase();
        const priority = (item.Priority || '').toLowerCase();
        const recordType = (item.RecordTypeName || '').toLowerCase();
        const contact = (item.ContactId || '').toLowerCase();
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